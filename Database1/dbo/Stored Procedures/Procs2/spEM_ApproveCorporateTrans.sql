CREATE PROCEDURE dbo.spEM_ApproveCorporateTrans
  @Trans_Id       int,
  @User_Id        int,
  @Group_Id       int,
  @Effective_Date DateTime
  AS
Declare @InsertId Int
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1, @User_Id,'spEM_ApproveCorporateTrans',  convert(nVarChar(10),@Trans_Id ) + ','  + convert(nVarChar(10),@User_Id ) + ','  + convert(nVarChar(10),@Group_Id ) + ','  +
 	 convert(nVarChar(25),@Effective_Date) ,dbo.fnServer_CmnGetDate(getUTCdate()))
select @InsertId = Scope_Identity()
  --
  -- Update the transaction record.
  --
  UPDATE Transactions  SET Approved_By = @User_Id,
        Approved_On = @Effective_Date,
        Effective_Date = @Effective_Date,
        Transaction_Grp_Id = @Group_Id
    WHERE Trans_Id = @Trans_Id
  UPDATE Transactions  SET Approved_By = @User_Id,
        Approved_On = @Effective_Date,
        Effective_Date = @Effective_Date,
        Transaction_Grp_Id = @Group_Id
    WHERE Corp_Trans_Id = @Trans_Id
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @InsertId
 RETURN(0)
