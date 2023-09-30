CREATE PROCEDURE dbo.spEM_OrderGroup
  @PUG_Id    int,
  @PUG_Order int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_OrderGroup',
                Convert(nVarChar(10),@PUG_Id) + ','  + 
 	  	 Convert(nVarChar(10), @PUG_Order) + ','  + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --   0 = Success
  --
  -- Order the group.
  --
  UPDATE PU_Groups SET PUG_Order = @PUG_Order WHERE PUG_Id = @PUG_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
