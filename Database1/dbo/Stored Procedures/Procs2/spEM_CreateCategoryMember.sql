CREATE PROCEDURE dbo.spEM_CreateCategoryMember
  @ERTD_ID Int,
  @ERC_Id  int,
  @User_Id Int,
  @NewId   Int output
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create user group.
  --
  DECLARE @Insert_Id integer 
  Declare @ID        Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateCategoryMember',
 	  	 Convert(nVarChar(10),@ERTD_ID) + ',' +
                Convert(nVarChar(10),@ERC_Id) + ',' +
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT INTO Event_Reason_Category_Data(ERC_Id,Event_Reason_Tree_Data_Id) VALUES(@ERC_Id,@ERTD_ID)
  Select @NewId = Scope_Identity()
  If @NewId is Null
     Rollback Transaction
  Else
    Begin 
      Commit Transaction
      /* add propagated from */
      Create Table #ChildId (ERTD_Id integer)
      Create Table #ChildId1 (ERTD_Id integer)
      Create Table #ChildId2 (ERTD_Id integer)
      Insert into #ChildId (ERTD_Id) Values (@ERTD_ID)
 Loop:
      Insert into #ChildId1 Select Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data where Parent_Event_R_Tree_Data_Id In (Select ERTD_Id From #ChildId)
      If @@Rowcount > 0 
        Begin
       	   Insert into #ChildId2 Select ERTD_Id From #ChildId1
 	   Delete From #ChildId
 	   Insert Into #ChildId Select ERTD_Id From #ChildId1
 	   Delete From #ChildId1 
 	   Goto Loop
        End
    Delete From Event_Reason_Category_Data Where ERC_Id = @ERC_Id and Event_Reason_Tree_Data_Id in (Select ERTD_Id From #ChildId2)
    Declare C Cursor  
    For Select  ERTD_Id From #ChildId2
    For Read Only
    Open C
CLOOP:
    Fetch Next From c InTo @ID
    If @@Fetch_Status = 0
      Begin
       Insert Into Event_Reason_Category_Data(ERC_Id,Event_Reason_Tree_Data_Id,Propegated_From_ETDId) VALUES(@ERC_Id,@ID,@ERTD_ID)
       Goto CLOOP
      End
     Close C
     Deallocate C 
     Drop Table #ChildId
     Drop Table #ChildId1
     Drop Table #ChildId2
    End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0  WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
