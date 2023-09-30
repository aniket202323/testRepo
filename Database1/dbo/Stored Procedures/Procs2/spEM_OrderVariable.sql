CREATE PROCEDURE dbo.spEM_OrderVariable
  @Var_Id    int,
  @PUG_Order int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Order the variable.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderVariable',
                Convert(nVarChar(10),@Var_Id) + ','  + 
 	  	 Convert(nVarChar(10), @PUG_Order) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  UPDATE Variables_Base SET PUG_Order = @PUG_Order WHERE Var_Id = @Var_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
