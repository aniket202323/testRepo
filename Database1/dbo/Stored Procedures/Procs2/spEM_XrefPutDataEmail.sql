CREATE PROCEDURE dbo.spEM_XrefPutDataEmail
 	 @EGId 	  	  	  	  	 Int,
 	 @TableId 	  	  	  	 Int,
 	 @ActualId 	  	  	  	 BigInt,
 	 @UserId 	  	  	  	  	 Int,
 	 @XRefId  	  	  	  	 Int  Output
  AS
 	 DECLARE @Insert_Id Int 
 	 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	  	 VALUES (1,1,'spEM_XrefPutDataEmail',
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@EGId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@TableId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@ActualId),'Null') + ','  + 
 	  	  	  	  	  	  	  	 Isnull(Convert(nVarChar(10), @UserId),'Null')  + ','  +
 	  	  	  	  	  	  	  	 IsNull(convert(nVarChar(10),@XRefId),'Null'),dbo.fnServer_CmnGetDate(getUTCdate()))
 	 select @Insert_Id = scope_identity()
If @XRefId is Null
Begin
 	 Select @XRefId = EG_XRef_Id From Email_Group_Xref  Where EG_Id = @EGId and Table_Id = @TableId and Key_Id = @ActualId
 	 If @XRefId is Null
 	 Begin
 	  	 Insert Into Email_Group_Xref (EG_Id,Table_Id,Key_Id) Values (@EGId,@TableId,@ActualId)
 	  	 Select @XRefId = SCOPE_IDENTITY()
 	  	 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
 	  	 Return(0)
 	 End
End
Return(0)
