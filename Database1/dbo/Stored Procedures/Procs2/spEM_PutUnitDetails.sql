Create Procedure dbo.spEM_PutUnitDetails
  @PU_Id int,
  @Production_Event_Association int,
  @Waste_Event_Association      int,
  @Timed_Event_Association      int,
  @Def_Measurement              nVarChar(100),
  @Def_Production_Dest          int,
  @Def_Production_Src           int,
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutUnitDetails',
                Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Production_Event_Association) + ','  + 
 	  	 Convert(nVarChar(10),@Waste_Event_Association) + ','  + 
 	  	 Convert(nVarChar(10),@Timed_Event_Association) + ','  + 
 	  	 LTRIM(RTRIM(@Def_Measurement)) + ','  + 
 	  	 Convert(nVarChar(10),@Def_Production_Dest) + ','  + 
 	  	 Convert(nVarChar(10),@Def_Production_Src) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  --
  -- Update the existing Production Unit.
    --
    UPDATE Prod_Units
      SET  Production_Event_Association = @Production_Event_Association,
           Waste_Event_Association      = @Waste_Event_Association,
           Timed_Event_Association      = @Timed_Event_Association,
           Def_Measurement              = (SELECT WEMT_Id FROM Waste_Event_Meas WHERE WEMT_Name = @Def_Measurement AND PU_Id = @PU_ID),
           Def_Production_Dest          = @Def_Production_Dest,
           Def_Production_Src           = @Def_Production_Src
      WHERE PU_Id = @PU_Id
  --
  -- Return success.
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
