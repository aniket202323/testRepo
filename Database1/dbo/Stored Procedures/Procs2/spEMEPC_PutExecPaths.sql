CREATE Procedure dbo.spEMEPC_PutExecPaths
@PL_Id int,
@Path_Desc nvarchar(50),
@Path_Code nvarchar(50),
@Is_Schedule_Controlled bit,
@Schedule_Control_Type tinyint,
@Is_Line_Production bit,
@Create_Children bit,
@User_Id int,
@Path_Id int = NULL OUTPUT
AS
Declare @x int,
@ID int,
@Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEMEPC_PutExecPaths',
             isnull(Convert(nVarChar(10),@PL_Id),'Null') + ','  + 
             isnull(Convert(nvarchar(50),@Path_Desc),'Null') + ','  + 
             isnull(Convert(nvarchar(50),@Path_Code),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Is_Schedule_Controlled),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Schedule_Control_Type),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Is_Line_Production),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Create_Children),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@User_Id),'Null') + ','  + 
             isnull(Convert(nVarChar(10),@Path_Id),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
If @Path_Id is NULL
  Begin
    If (Select Count(*) From Prdexec_Paths Where Path_Code = ltrim(rtrim(@Path_Code))) > 0
      Return(-100)
    If @Path_Desc is NULL or LTrim(RTrim(@Path_Desc)) = ''
      Select @Path_Desc = 'Path Description'
    If @Path_Code is NULL or LTrim(RTrim(@Path_Code)) = ''
      Begin
        Select @x = 0
        NextAvailCode:
        Select @x = @x + 1
        Select @ID = Null
        Select @ID = Path_Id From Prdexec_Paths
        where Path_Code = 'Path Code ' + Convert(nVarChar(10), @x)
        If @ID is Null
          Begin
            Select @Path_Code = 'Path Code ' + Convert(nVarChar(10), @x)
          End
        Else
          Begin
            Goto NextAvailCode
          End
      End
    Insert Into Prdexec_Paths (PL_Id, Path_Desc, Path_Code, Is_Schedule_Controlled, Schedule_Control_Type, Is_Line_Production, Create_Children)
      Values (@PL_Id, @Path_Desc, @Path_Code, @Is_Schedule_Controlled, @Schedule_Control_Type, @Is_Line_Production, @Create_Children)
    Select @Path_Id = Scope_Identity()
 	  	 Declare @PendingId int, @NextId int, @ActiveId int, @CompleteId int,@PlanningId int
 	  	 
 	  	 Select @PendingId = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = 'Pending'
 	  	 Select @NextId = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = 'Next'
 	  	 Select @ActiveId = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = 'Active'
 	  	 Select @CompleteId = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = 'Complete'
 	  	 Select @PlanningId = PP_Status_Id From Production_Plan_Statuses Where PP_Status_Desc = 'Planning'
 	  	 INSERT INTO PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, How_Many, Sort_Order) 
 	  	  	 VALUES (@Path_Id, @PendingId, NULL, NULL, NULL, 1)
 	  	 INSERT INTO PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, How_Many, Sort_Order) 
 	  	  	 VALUES (@Path_Id, @NextId, NULL, NULL, 1, 2)
 	  	 INSERT INTO PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, How_Many, Sort_Order) 
 	  	  	 VALUES (@Path_Id, @ActiveId, @PendingId, @NextId, 1, 3)
 	  	 INSERT INTO PrdExec_Path_Status_Detail (Path_Id, PP_Status_Id, AutoPromoteFrom_PPStatusId, AutoPromoteTo_PPStatusId, How_Many, Sort_Order) 
 	  	  	 VALUES (@Path_Id, @CompleteId, @NextId, @ActiveId, NULL, 4) 	  	  	  	 
 	   If @PendingId > 0 and @NextId > 0
 	     Begin
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @PendingId, @NextId)
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @NextId, @PendingId)
 	     End
 	  	   
 	   If @NextId > 0 and @ActiveId > 0
 	     Begin
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @NextId, @ActiveId)
 	     End
 	   
 	   If @ActiveId > 0 and @PendingId > 0
 	     Begin
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @ActiveId, @PendingId)
 	     End
 	   
 	   If @ActiveId > 0 and @CompleteId > 0
 	     Begin
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @ActiveId, @CompleteId)
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @CompleteId, @ActiveId)
 	     End
 	   
 	   If @PendingId > 0 and @PlanningId > 0
 	     Begin
        INSERT INTO Production_Plan_Status (Path_Id, From_PPStatus_Id, To_PPStatus_Id) Values (@Path_Id, @PendingId, @PlanningId)
 	     End
 	  
  End
Else If @Path_Id is NOT NULL and @PL_Id is NOT NULL
  Begin
    If (Select Count(*) From Prdexec_Paths Where Path_Code = ltrim(rtrim(@Path_Code)) and Path_Id <> @Path_Id) > 0
      Return(-100)
    Update Prdexec_Paths
      Set Path_Desc = @Path_Desc, Path_Code = @Path_Code, Is_Schedule_Controlled = @Is_Schedule_Controlled, 
          Schedule_Control_Type = @Schedule_Control_Type, Is_Line_Production = @Is_Line_Production,
          Create_Children = @Create_Children
    Where Path_Id = @Path_Id
  End
Else If @Path_Id is NOT NULL and @PL_Id is NULL
  Begin
    Delete From Table_Fields_Values Where KeyId = @Path_Id and TableId = 13
    Delete From PrdExec_Path_Alarms Where Path_Id = @Path_Id
    Delete From PrdExec_Path_Status_Detail Where Path_Id = @Path_Id
    Delete From Production_Plan_Status Where Path_Id = @Path_Id
    Declare @Comment_Id int
    Select @Comment_Id = Comment_Id From Prdexec_Paths Where Path_Id = @Path_Id
    If @Comment_Id is not null
      Update Comments Set Comment = '', Comment_Text = '', ShouldDelete = 1 Where Comment_Id = @Comment_Id
 	  Update Production_Plan set path_Id = Null where Path_Id = @Path_Id
    Delete From PrdExec_Path_Input_Source_Data
      Where PEPIS_Id in (Select PEPIS_Id From PrdExec_Path_Input_Sources Where Path_Id = @Path_Id)
    Delete From PrdExec_Path_Input_Sources
      Where Path_Id = @Path_Id
    Delete From PrdExec_Path_Inputs
      Where Path_Id = @Path_Id
    Delete From PrdExec_Path_Products
      Where Path_Id = @Path_Id
    Delete From PrdExec_Path_Units
      Where Path_Id = @Path_Id
    Delete From PrdExec_Path_Unit_Starts
      Where Path_Id = @Path_Id
    Delete From Sheet_Paths
      Where Path_Id = @Path_Id
    Update Prod_Units set Default_Path_Id = Null Where Default_Path_Id = @Path_Id
    Delete From Prdexec_Paths
      Where Path_Id = @Path_Id
  End
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @Insert_Id
