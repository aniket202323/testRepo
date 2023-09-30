/* This sp is called by dbo.spBatch_CheckEventTable parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_SetMasterUnit
  @PU_Id       int,
  @Master_Unit int,
  @User_Id int
  AS
  --
  -- If the master unit has a master unit, make this parent the new master unit.
  --
  DECLARE @Insert_Id integer, @New_Master int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_SetMasterUnit',
                Convert(nVarChar(10),@PU_Id) + ','  + 
                Convert(nVarChar(10),@Master_Unit) + ','  + 
                Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @New_Master = Master_Unit FROM Prod_Units WHERE (PU_Id = @Master_Unit)
  IF @New_Master IS NULL SELECT @New_Master = @Master_Unit
  --
  -- Update the master unit of the target and its children.
  --
  IF @Master_Unit IS NULL
 	 Begin
 	   -- Slave to Master or change of Master
 	   UPDATE Prod_Units SET Master_Unit = @New_Master WHERE PU_Id = @PU_Id
 	   IF @New_Master is NULL and (select count(*) From PrdExec_Status Where PU_Id = @PU_Id) = 0
 	   BEGIN
 	  	 INSERT INTO PrdExec_Status (PU_Id,Step,Valid_Status,Is_Default_Status)
 	  	  	 SELECT @PU_Id,1,Null,Null
 	  	 -- Default Statuses
 	  	 Declare @StatusId Int
 	  	 Declare @StatusId1 Int
 	  	 Declare Status_Cursor Cursor For Select ProdStatus_Id From Production_Status
 	  	  	 Where ProdStatus_Id In (5,8,9,10,11,12)
 	  	  	 Open Status_Cursor
 	  	 StatusCursorLoop:
 	  	 Fetch Next From Status_Cursor Into @StatusId
 	  	 If @@Fetch_Status = 0
 	  	 Begin
 	  	  	 INSERT INTO PrdExec_Status (PU_Id,Step,Valid_Status,Is_Default_Status)
 	  	  	 SELECT @PU_Id,1,@StatusId,Case When @StatusId = 5 then 1 Else 0 End
 	  	  	 Declare Status_Cursor1 Cursor For Select ProdStatus_Id From Production_Status
 	  	  	  	 Where ProdStatus_Id In (5,8,9,10,11,12) and ProdStatus_Id <> @StatusId
 	  	  	  	 Open Status_Cursor1
 	  	 StatusCursorLoop1:
 	  	  	 Fetch Next From Status_Cursor1 Into @StatusId1
 	  	  	 If @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	  	 INSERT INTO PrdExec_Trans (PU_Id,From_ProdStatus_Id,To_ProdStatus_Id)
 	  	  	  	 SELECT @PU_Id,@StatusId, @StatusId1
 	  	  	  	 Goto StatusCursorLoop1
 	  	  	 End
 	  	  	 Close Status_Cursor1
 	  	  	 Deallocate Status_Cursor1
 	  	  	 Goto StatusCursorLoop
 	  	 End
 	  	 Close Status_Cursor
 	  	 Deallocate Status_Cursor
 	   END
 	 End
  ELSE
 	 Begin
 	   -- Master to Slave
 	   UPDATE Prod_Units SET Master_Unit = @New_Master
 	  	 WHERE (PU_Id = @PU_Id) OR (Master_Unit = @PU_Id)
 	   DELETE FROM PrdExec_Trans WHERE PU_Id = @PU_Id
 	   DELETE FROM prdexec_status WHERE PU_Id = @PU_Id
 	 End
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0  WHERE Audit_Trail_Id = @Insert_Id
