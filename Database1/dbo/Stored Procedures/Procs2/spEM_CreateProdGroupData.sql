CREATE PROCEDURE dbo.spEM_CreateProdGroupData
  @Product_Grp_Id int,
  @Prod_Id        int,
  @User_Id        int,
  @PGD_Id         int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Unable to create product group data.
  --
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProdGroupData',
                 convert(nVarChar(10),@Product_Grp_Id) + ','  + Convert(nVarChar(10),  @Prod_Id ) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  INSERT Product_Group_Data(Product_Grp_Id, Prod_Id) VALUES(@Product_Grp_Id, @Prod_Id)
  SELECT @PGD_Id = Scope_Identity()
  IF @PGD_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PGD_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
