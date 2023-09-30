CREATE PROCEDURE dbo.spEM_EUDropEU
  @EngUnitId      Int,
  @User_Id        Int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_EUDropEU',
       Convert(nVarChar(10),@EngUnitId)  + ',' +
 	      Convert(nVarChar(10), @User_Id),   dbo.fnServer_CmnGetDate(getUTCdate()))
  select @Insert_Id = Scope_Identity()
 	 If (Select Count(*) from Bill_Of_Material_Formulation_Item Where Eng_Unit_Id = @EngUnitId) > 0
 	  	 Return (-100)
 	 If (Select Count(*) from Bill_Of_Material_Substitution Where Eng_Unit_Id = @EngUnitId) > 0
 	  	 Return (-100)
 	 If (Select Count(*) from Engineering_Unit_Conversion Where From_Eng_Unit_Id = @EngUnitId or To_Eng_Unit_Id = @EngUnitId ) > 0
 	  	 Return (-100)
  BEGIN TRANSACTION
  Delete From Engineering_Unit Where Eng_Unit_Id = @EngUnitId
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@EngUnitId) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
