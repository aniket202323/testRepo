CREATE PROCEDURE dbo.spEM_IEImportReasonTrees
 	 @Tree_Name 	  	 nvarchar(50),
 	 @Group_Desc 	  	 nvarchar(50),
 	 @Title1 	  	  	 nvarchar(50),
 	 @Title2 	  	  	 nvarchar(50),
 	 @Title3 	  	  	 nvarchar(50),
 	 @Title4 	  	  	 nvarchar(50),
 	 @User_Id 	  	 Int
AS
Declare @Group_Id 	  	 int,
 	  	 @Description  	 nVarChar(100),
 	  	 @Phrase_Order  	 int,
 	  	 @Header_Id 	  	 int,
 	  	 @Level_Name 	  	 nvarchar(50),
 	  	 @Reason_Levels 	 int,
 	  	 @Reason_Level 	 int,
 	  	 @Old_Level_Name 	 nvarchar(50),
 	  	 @sLevel 	  	  	 nvarchar(500),
 	  	 @Tree_Name_Id 	 int 
/* Initialization */
Select  	 @Group_Id  	  	 = Null,
 	 @Tree_Name_Id  	 = Null,
 	 @Reason_Levels 	 = 4,
 	 @Reason_Level 	 = 1
/* Clean arguments */
Select  	 @Tree_Name  	 = RTrim(LTrim(@Tree_Name)),
 	 @Group_Desc  	 = RTrim(LTrim(@Group_Desc)),
 	 @Title1 	  	 = RTrim(Ltrim(@Title1)),
 	 @Title2 	  	 = RTrim(Ltrim(@Title2)),
 	 @Title3 	  	 = RTrim(Ltrim(@Title3)),
 	 @Title4 	  	 = RTrim(Ltrim(@Title4))
/* Get Security Group */
If @Group_Desc Is Not Null And @Group_Desc <> ''
  Begin
     Select @Group_Id = Group_Id
     From Security_Groups
     Where Group_Desc = @Group_Desc
     If @Group_Id Is Null
       Begin
          Select 'Failed - Invalid security group.'
          Return (-100)
       End
  End
If @Tree_Name Is Not Null And @Tree_Name <> ''
  Begin
     /* Check for existing tree */
     Select @Tree_Name_Id = Tree_Name_Id
     From Event_Reason_Tree
     Where Tree_Name = @Tree_Name
     /* Import/Update Tree data */
     If @Tree_Name_Id Is  Null
        Begin
 	  	   Execute spEM_CreateReasonTreeName @Tree_Name,@User_Id, @Tree_Name_Id  OUTPUT 
          /* Check for errors */
          If @Tree_Name_Id  Is Null
            Begin
 	  	  	  	 Select 'Failed - Unable to create tree'
               Return (-100)
            End
          End
 	  	 Execute spEM_PutSecurityReasonTree  @Tree_Name_Id, @Group_Id,@User_Id
     While @Reason_Level <= @Reason_Levels
        Begin
          Select @Level_Name = Case @Reason_Level
 	  	  	  	 When 1 Then @Title1
 	  	  	  	 When 2 Then @Title2
 	  	  	  	 When 3 Then @Title3
 	  	  	  	 When 4 Then @Title4
 	  	  	  	 Else Null
 	  	  	          End
          If @Level_Name Is Not Null And @Level_Name <> ''
             Begin
               Select 	 @Header_Id  	 = Null,@Old_Level_Name = Null
               Select @Header_Id = Event_Reason_Level_Header_Id, @Old_Level_Name = Level_Name
                 From Event_Reason_Level_Headers
                 Where Tree_Name_Id = @Tree_Name_Id And Reason_Level = @Reason_Level
               If @Header_Id Is Not Null
 	  	  	  	 Begin
                  If @Level_Name <> @Old_Level_Name
 	  	  	  	  	 Execute spEM_RenameReasonTreeHeader   @Header_Id,@Level_Name,@User_Id
 	  	  	  	 End
               Else
                 Begin
 	  	  	  	  	 Execute spEM_CreateReasonTreeHeader @Tree_Name_Id, @Level_Name,@User_Id,@Header_Id OUTPUT 
                    If @Header_Id Is Null
                      Begin
                         Select 'Failed - Unable to create header [' + @Level_Name + ']'
                         Return (-100)
                      End
                    End
             End
          Else
             Break
          Select @Reason_Level = @Reason_Level + 1
        End
     Return(0)
  End
Else
  Begin
     Select 'Failed - Tree Name Not Found.'
     Return (-100)
  End
