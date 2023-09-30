CREATE PROCEDURE dbo.spEM_CreateCharGroupData
  @Char_Grp_Id int,
  @Char_Id        int,
  @User_Id int,
  @CGD_Id         int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Unable to create product group data.
  --
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateCharGroupData',
                 convert(nVarChar(10),@Char_Grp_Id) + ','  + Convert(nVarChar(10), @Char_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT Characteristic_Group_Data(Characteristic_Grp_Id, Char_Id) VALUES(@Char_Grp_Id, @Char_Id)
  SELECT @CGD_Id = Scope_Identity()
  IF @CGD_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@CGD_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
