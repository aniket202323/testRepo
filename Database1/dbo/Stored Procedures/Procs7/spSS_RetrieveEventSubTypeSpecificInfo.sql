Create Procedure dbo.spSS_RetrieveEventSubTypeSpecificInfo
 @EventSubTypeString nVarChar(255),
 @RunType int
AS
 Declare @NoCause nVarChar(25),
         @NoAction nVarChar(25),
         @CurrInputString nVarChar(255),
         @CurrentChar char,
         @CharCount int,
         @CurrentIDString nVarChar(10),
         @ConvertedID int
 Select @NoCause = '<Any>'
 Select @NoAction = '<Any>'
 Create Table #CauseTree (Tree_Id int NULL)  
 Create Table #ActionTree (Tree_Id int NULL)
 Create Table #EventIds (Event_SubType_Id int)
--------------------------------------------------------
-- Populate the EventIds table
--------------------------------------------------------
Select @CurrInputString = ''
Select @CurrentIDString = ''
Select @CurrInputString = @EventSubTypeString
Select @CharCount = 1
Select @CurrentChar = SubString(@CurrInputString, @CharCount, 1)
While (@CurrentChar <> '$') and (@CharCount < 254)
    Begin
        If @CurrentChar <> ',' and @CurrentChar <> '_'
            Select @CurrentIDString = @CurrentIDString + @CurrentChar
        Else
           Begin
                Select @CurrentIDString = Ltrim(Rtrim(@CurrentIDString))
                If @CurrentIDString <> ''
                    Begin
                         Select @ConvertedID = Convert(Integer, @CurrentIDString)
                         Insert #EventIds Values(@ConvertedID)
                    End
 	  	 If @CurrentChar = ','
                    Begin
                         Select @CurrentIDString = ''
                    End
           End
        Select @CharCount = @CharCount + 1
        Select @CurrentChar = SubString(@CurrInputString, @CharCount, 1)
    End
-- Catch the last EventSubType Id
Select @CurrentIDString = Ltrim(Rtrim(@CurrentIDString))
If @CurrentIDString <> ''
    Begin
        Select @ConvertedID = Convert(Integer, @CurrentIDString)
        Insert #EventIds Values(@ConvertedID)
    End
--------------------------------------------------------
-- Get the tree ids used by alarms, and gets all levels for them
--------------------------------------------------------
if @RunType = 1 
 Begin
 Insert Into #CauseTree
  Select Distinct Cause_Tree_Id
   From Event_SubTypes es
    Join #EventIds e on es.Event_Subtype_Id = e.Event_SubType_Id
    Where es.ET_Id = 14 
     And es.Cause_Tree_Id Is Not Null
 Select 0 as Event_Reason_Id,  Event_Reason_Name = @NoCause, parent_Event_Reason_Id = 0 , Event_Reason_Level = 0
  Union
  Select Distinct Event_Reason_Id = D.Event_Reason_Id, Event_Reason_Name = E.Event_Reason_Name, Parent_Event_Reason_Id = D.Parent_Event_Reason_Id,
                  Event_Reason_Level = D.Event_Reason_Level
   From Event_Reason_Tree_Data D 
   Join #CauseTree T On D.Tree_Name_Id = T.Tree_Id
   Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
    Order by Event_Reason_Name
--------------------------------------------------------
-- Get the tree ids used by alarms, and gets all levels for them
--------------------------------------------------------
 Insert Into #ActionTree
  Select Distinct Action_Tree_Id
   From Event_SubTypes es
    Join #EventIds e on es.Event_Subtype_Id = e.Event_SubType_Id
    Where es.ET_Id = 14 
     And es.Action_Tree_Id Is Not Null
  Select Event_Reason_Id = 0, Event_Reason_Name = @NoAction ,  parent_Event_Reason_Id = 0, Event_Reason_Level = 0
  Union
  Select Distinct Event_Reason_Id = D.Event_Reason_Id, Event_Reason_Name = E.Event_Reason_Name, Parent_Event_Reason_Id = D.Parent_Event_R_Tree_Data_Id,
                  Event_Reason_Level = D.Event_Reason_Level
   From Event_Reason_Tree_Data D Inner Join #ActionTree T On D.Tree_Name_Id = T.Tree_Id
                                 Inner Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
    Order by Event_Reason_Name
 End
Else
 Begin
  Insert Into #CauseTree
   Select Distinct Cause_Tree_Id
    From Event_SubTypes
     Where ET_Id = 14 
      And Cause_Tree_Id Is Not Null
   Select 0 as Event_Reason_Id, @NoCause as Event_Reason_Name, 0 as parent_Event_Reason_Id, 0 as Event_Reason_Level
   Union
   Select Distinct D.Event_Reason_Id, E.Event_Reason_Name, D.Parent_Event_Reason_Id,
                   D.Event_Reason_Level
    From Event_Reason_Tree_Data D Inner Join #CauseTree T On D.Tree_Name_Id = T.Tree_Id
                                  Inner Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
     Order by E.Event_Reason_Name
--------------------------------------------------------
-- Get the tree ids used by alarms, and gets all levels for them
--------------------------------------------------------
  Insert Into #ActionTree
   Select Distinct Action_Tree_Id
    From Event_SubTypes
     Where ET_Id = 14 
      And Action_Tree_Id Is Not Null
   Select Event_Reason_Id = 0, Event_Reason_Name = @NoAction, parent_Event_Reason_Id =0 , Event_Reason_Level = 0
   Union
   Select Distinct Event_Reason_Id = D.Event_Reason_Id, Event_Reason_Name = E.Event_Reason_Name, Parent_Event_Reason_Id = D.Parent_Event_Reason_Id,
                   Event_Reason_Level = D.Event_Reason_Level
    From Event_Reason_Tree_Data D Inner Join #ActionTree T On D.Tree_Name_Id = T.Tree_Id
                                  Inner Join Event_Reasons E On E.Event_Reason_Id = D.Event_Reason_Id
     Order by Event_Reason_Name
 End
 Drop Table #CauseTree
 Drop Table #ActionTree
 Drop Table #EventIds
