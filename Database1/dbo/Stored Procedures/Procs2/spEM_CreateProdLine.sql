/* This sp is called by dbo.spBatch_CreateBatchUnit parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateProdLine
  @Description nvarchar(50),
  @DeptId 	 Int,
  @User_Id  	 int,
  @PL_Id    int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Can't create production line.
  --
  DECLARE @Insert_Id integer,@Sql nvarchar(1000)
  Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateProdLine',
                 @Description + ','  + Convert(nVarChar(10), @DeptId) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  Select @Insert_Id = Scope_Identity()
  INSERT INTO Prod_Lines(PL_Desc,Dept_Id) 	 VALUES(@Description, @DeptId)
  SELECT @PL_Id = PL_Id From Prod_Lines Where PL_Desc = @Description
  IF @PL_Id IS NULL
 	 BEGIN
 	     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
 	     RETURN(1)
 	 END
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@PL_Id) where Audit_Trail_Id = @Insert_Id
RETURN(0)
