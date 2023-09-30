/* This sp is called by dbo.spBatch_ProcessProcedureReport parameters need to stay in sync*/
CREATE PROCEDURE dbo.spEM_CreateTransaction
  @Trans_Desc nvarchar(50),
  @Corp_Trans_Id    int,
  @Trans_Type Int,
  @Corp_Trans_Desc  nvarchar(25),
  @User_Id int,
  @Trans_Id   int OUTPUT
  AS
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateTransaction',
                @Trans_Desc + ','  + convert(nVarChar(10),@Corp_Trans_Id) +  ',' + convert(nVarChar(10),@Trans_Type) +  ','  +@Corp_Trans_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  --
  IF @Corp_Trans_Id IS NOT NULL  
 	 SELECT @Trans_Type =  2
  If @Trans_Type is Null 
 	 SELECT @Trans_Type =  1
  INSERT INTO Transactions(Trans_Desc,Trans_Type_Id,Corp_Trans_Desc,Corp_Trans_Id,Trans_Create_Date) 
 	 VALUES(@Trans_Desc, @Trans_Type, @Corp_Trans_Desc,@Corp_Trans_Id,dbo.fnServer_CmnGetDate(getUTCdate()))
  If @@Error = 0
   	 SELECT @Trans_Id = Scope_Identity()
  IF @Trans_Id IS NULL 
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Trans_Id)
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(0)
