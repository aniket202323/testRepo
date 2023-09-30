CREATE PROCEDURE dbo.spEM_PutSecurityUnit
  @PU_Id    int,
  @Group_Id int,
  @User_Id int
  AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSecurityUnit',
                	 Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Group_Id) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success.
  --
  -- Update the production unit's security group.
  --
  UPDATE Prod_Units SET Group_Id = @Group_Id WHERE PU_Id = @PU_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
