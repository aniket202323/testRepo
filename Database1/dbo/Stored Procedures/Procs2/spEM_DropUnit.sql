CREATE PROCEDURE dbo.spEM_DropUnit
  @PU_Id int,
  @User_Id   int
 AS
  --
  -- Return Codes:
  --
  --       0 = Success
  --   50101 = Variable Error
  --   50102 = Group Error
  --   50103 = Unit Error
  --
  -- Begin a transaction.
  --
  -- Drop all Groups (and variables)
  DECLARE        @UntReturnCode  	 int,
 	  	 @UntGrp_Id 	  	 int ,
 	  	 @UntSht_Id  	  	 int,
 	  	 @UntSlave_Id  	  	 int,
 	  	 @SaveUnitCode  	 int,
 	  	 @Insert_Id  	  	 int,
 	  	 @EC_Id  	  	 int,
 	  	 @EventId 	  	 Int,
    @Sheet_Id int, 
    @SheetTypeId int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropUnit',
                 convert(nVarChar(10),@PU_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 SELECT @SaveUnitCode = 0
  --
  -- 
  --
    DECLARE Unt_Cursor CURSOR
    FOR SELECT PUG_Id FROM PU_Groups WHERE PU_Id = @PU_Id
    FOR READ ONLY
    OPEN Unt_Cursor
    Fetch_Next_UntGrp:
    FETCH NEXT FROM Unt_Cursor INTO @UntGrp_Id
    IF @@FETCH_STATUS = 0
    BEGIN
 	 EXECUTE @UntReturnCode = spEM_DropGroup @UntGrp_Id,@User_Id
 	 IF @UntReturnCode = 0 GOTO Fetch_Next_UntGrp
        ELSE
          BEGIN
            SELECT @SaveUnitCode = @UntReturnCode
            GOTO Fetch_Next_UntGrp
          END
    END
    ELSE IF @@FETCH_STATUS = -1
 	    SELECT @UntReturnCode = 0
         ELSE
 	  BEGIN
 	   RAISERROR('Fetch error for Var_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	     @@FETCH_STATUS)
 	   SELECT @UntReturnCode = 50103
         END
  DEALLOCATE Unt_Cursor
  -- If successful, delete the production group to be dropped and commit the transaction.
  -- Otherwise, roll the transaction back.
  --
  IF @UntReturnCode = 0
    BEGIN  	 
 	 --
 	 -- Promote any slave production units of the production unit
 	 -- to be dropped to masters.
        -- Clear out any products or Characteristics for the slaves  
 	 --
      DECLARE Slave_Cursor CURSOR 	 
 	  	 FOR SELECT PU_Id FROM Prod_Units WHERE Master_Unit = @PU_Id
 	  	 FOR READ ONLY
        OPEN Slave_Cursor
        Fetch_Next_Slave:
        FETCH NEXT FROM Slave_Cursor INTO @UntSlave_Id
        IF @@FETCH_STATUS = 0
          BEGIN
 	      	 DELETE FROM PU_Characteristics   WHERE PU_Id = @UntSlave_Id
 	  	  	 DELETE FROM PU_Products          WHERE PU_Id = @UntSlave_Id
 	  	  	 DELETE FROM Trans_Characteristics WHERE PU_Id = @UntSlave_Id
 	  	  	 Delete From Trans_Products     Where PU_Id = @UntSlave_Id
            UPDATE Prod_Units SET Master_Unit = NULL WHERE PU_Id = @UntSlave_Id
            GOTO Fetch_Next_Slave
          END
         ELSE IF @@FETCH_STATUS = -1
 	    SELECT @UntReturnCode = 0
         ELSE
 	    BEGIN
 	     RAISERROR('Fetch error for Unit Slave Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	       @@FETCH_STATUS)
 	     SELECT @UntReturnCode = 50103
           END
        DEALLOCATE Slave_Cursor
     END
     IF @UntReturnCode = 0
       BEGIN
        --
 	 -- Delete event related items associated with unit.
 	 --
 	 SELECT Event_Id INTO #Evt FROM Events WHERE PU_Id = @PU_Id Order by timestamp
 	 Execute ('Declare ECursor Cursor Global  For ' +
 	    'Select Event_ID From #Evt For Read only')
 	 Open ECursor
Loop:
 	 Fetch Next From ECursor Into @EventId
 	 If @@Fetch_Status = 0
 	    Begin
 	      Execute spEM_DropEvent @EventId
 	      Goto Loop
 	   End
 	 DROP TABLE #Evt
 	 Close ECursor
 	 Deallocate ECursor
 	 --
 	 -- Delete any timed event details associated with the unit.
 	 --
 	 SELECT TEDet_Id INTO #TED FROM Timed_Event_Details WHERE PU_Id = @PU_Id
 	 DELETE FROM Timed_Event_Details WHERE TEDet_Id IN (SELECT TEDet_Id FROM #TED)
 	 DROP TABLE #TED
 	 --
 	 -- Delete any waste event details associated with the unit.
 	 --
 	 SELECT WED_Id INTO #WED FROM Waste_Event_Details WHERE PU_Id = @PU_Id
 	 DELETE FROM Waste_Event_Details WHERE WED_Id IN (SELECT WED_Id FROM #WED)
 	 DROP TABLE #WED
 	 --
 	 -- Handle source rpoduction units for event stuff.
 	 -- 
 	 UPDATE Timed_Event_Details  SET Source_PU_Id = NULL WHERE Source_PU_Id = @PU_Id
 	 UPDATE Waste_Event_Details  SET Source_PU_Id = NULL WHERE Source_PU_Id = @PU_Id
 	 --
 	 -- Delete miscellaneous object associated with the production unit.
 	 --
 	 DELETE FROM Trans_Characteristics WHERE PU_Id = @PU_Id
 	 DELETE FROM PU_Characteristics        WHERE PU_Id = @PU_Id
 	 Delete From Trans_Products     Where PU_Id = @PU_Id
 	 DELETE FROM PU_Characteristics        WHERE PU_Id = @PU_Id
 	 -- Event Configuration
 	 Select Ec_Id into #EC From Event_Configuration Where PU_Id = @PU_Id
 	 Execute ('DECLARE EC_Cursor CURSOR Global   ' + 	 
 	  	   'FOR SELECT Ec_Id FROM #EC ' +
 	  	   'FOR READ ONLY')
 	 OPEN EC_Cursor
 	 Fetch_Next_EC:
 	 FETCH NEXT FROM EC_Cursor INTO @EC_Id
 	 IF @@FETCH_STATUS = 0
 	   BEGIN
 	      Execute spEMDT_DeleteEC @EC_Id,@User_Id
 	     Goto  Fetch_Next_EC
      End
 	 Close EC_Cursor
 	 Deallocate EC_Cursor
 	 Select ECV_Id into #ECV From Event_Configuration_Data Where PU_Id = @PU_Id
 	 Delete From Event_Configuration_Data Where PU_Id = @PU_Id
 	 Delete From Event_Configuration_Values where ECV_Id in (select ECV_Id from #ECV)
 	 Drop Table #ECV
 	 Execute spEMEPC_ExecPathConfig_TableMod 96,@PU_Id,Null,Null,Null,Null,@User_Id
 	 Delete From PrdExec_Path_Input_Sources where pu_Id = @PU_Id
 	 Delete From PrdExec_Path_Units where pu_Id = @PU_Id
 	 Delete From PrdExec_Status where pu_Id = @PU_Id
 	 Delete From PrdExec_Trans where pu_Id = @PU_Id
 	 Delete From Production_Plan_Starts where pu_Id = @PU_Id
 	 Delete From Production_Status_XRef where pu_Id = @PU_Id
 	 Delete From Sheet_Genealogy_Data where pu_Id = @PU_Id
 	 DELETE FROM GB_DSet                   WHERE PU_Id = @PU_Id 
 	 DELETE FROM GB_RSum                   WHERE PU_Id = @PU_Id
 	 DELETE FROM PU_Products               WHERE PU_Id = @PU_Id
 	 DELETE FROM PreEvents                 WHERE PU_Id = @PU_Id
 	 DELETE FROM Prod_XRef                 WHERE PU_Id = @PU_Id
 	 DELETE FROM Reason_Shortcuts          WHERE PU_Id = @PU_Id
 	 DELETE FROM Report_Shortcuts          WHERE PU_Id = @PU_Id
 	 DELETE FROM Spool_Weights             WHERE PU_Id = @PU_Id
 	 DELETE From Timed_Event_Status        WHERE PU_Id = @PU_Id
 	 Delete From Waste_Event_Details 	       Where WEMT_Id in (Select WEMT_Id From  Waste_Event_Meas          WHERE PU_Id = @PU_Id)
 	 DELETE From Waste_Event_Meas          WHERE PU_Id = @PU_Id
 	 DELETE From Waste_Event_Fault         WHERE PU_Id = @PU_Id
 	 Update Waste_Event_Fault   Set Source_PU_Id = Null,Reason_Level1 = Null,Reason_Level2 = Null,Reason_Level3 = Null,Reason_Level4 = Null,Event_Reason_Tree_Data_Id = Null  WHERE Source_PU_Id = @PU_Id
 	 DELETE From Timed_Event_Fault         WHERE PU_Id = @PU_Id
 	 Update Timed_Event_Fault   Set Source_PU_Id = Null,Reason_Level1 = Null,Reason_Level2 = Null,Reason_Level3 = Null,Reason_Level4 = Null,Event_Reason_Tree_Data_Id = Null  WHERE Source_PU_Id = @PU_Id
 	 DELETE FROM Prod_Events               WHERE PU_Id = @PU_Id
   	 DELETE FROM Crew_Schedule             WHERE PU_Id = @PU_Id
 	 Delete From PrdExec_Input_Source_Data Where PEIS_Id In (Select PEIS_Id From  PrdExec_Input_Sources  Where PU_Id = @PU_Id)
 	 Delete From PrdExec_Input_Sources     Where PU_Id = @PU_Id
 	 Update User_Defined_Events set Parent_UDE_Id = Null Where Parent_UDE_Id In ( Select UDE_Id from  User_Defined_Events Where PU_Id = @PU_Id)
 	 Delete From User_Defined_Events       Where PU_Id = @PU_Id
 	 Delete From Container_Location_History Where PU_Id = @PU_Id
 	 Delete From Container_Location         Where PU_Id = @PU_Id
 	 Delete From Defect_Details 	        Where PU_Id = @PU_Id
 	 Delete From PU_Defects 	  	        Where PU_Id = @PU_Id
 	 Delete From Saved_Queries 	        Where PU_Id = @PU_Id
 	 Delete From Template_Property_Data     Where PU_Id = @PU_Id
 	 Delete From Bill_Of_Material_Substitution where BOM_Formulation_Item_Id in (select BOM_Formulation_Item_Id From Bill_Of_Material_Formulation_Item Where PU_Id = @PU_Id)
 	 Delete From Bill_Of_Material_Formulation_Item     Where PU_Id = @PU_Id
 	 update Bill_Of_Material_Product set PU_Id=null where PU_Id=@PU_Id
 	 delete from bp from Bill_Of_Material_Product bp inner join Bill_Of_Material_Product bp2 on bp.Prod_Id=bp2.Prod_Id and bp.BOM_Formulation_Id=bp2.BOM_Formulation_Id and bp.PU_Id is null and bp2.PU_Id is not null
    --
 	 --   
 	 -- Inactivate any Sheets
 	 -- 
 	 Update Sheets Set Master_Unit = null,Is_Active = 0 where Master_Unit = @PU_Id
 	 --Production Units run twice in case icons and PEP were saved
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'ah',0
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'ah',0
 	 --External Units
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'an',0
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'an',0
 	 --Sheet Units
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'ah',1
 	 Execute spEM_cmnCleanUpPEP @PU_Id,'ah',1
 	 Delete From Sheet_Unit Where PU_Id = @PU_Id
 	 --
 	 -- Delete any production start related items associated with the unit.
 	 --
 	 DELETE FROM Production_Starts WHERE  PU_Id = @PU_Id
 	 DELETE FROM PAEquipment_Aspect_SOAEquipment  WHERE PU_Id = @PU_Id
 	 IF @UntReturnCode = 0
 	   BEGIN
 	     DELETE FROM Prod_Units_Base WHERE PU_Id = @PU_Id
        IF @@ERROR <> 0 SELECT @UntReturnCode = 50103
 	   END
   END
  IF @SaveUnitCode = 0 SELECT @SaveUnitCode = @UntReturnCode
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @SaveUnitCode
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(@SaveUnitCode)
