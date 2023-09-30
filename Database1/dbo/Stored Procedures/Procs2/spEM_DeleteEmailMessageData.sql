CREATE PROCEDURE dbo.spEM_DeleteEmailMessageData
 	 @MessageId 	 Int,
 	 @UserId 	  	 Int
AS
 DECLARE @InsertId integer 
 Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEM_DeleteEmailMessageData',  convert(nVarChar(10),@MessageId) + ','   + Convert(nVarChar(10), @Userid),dbo.fnServer_CmnGetDate(getUTCdate()))
 select @InsertId = scope_Identity()
If @MessageId < 0 return(0)
Delete  tfv
 	 From  Table_Fields_Values tfv
 	 Join Table_Fields tf On tfv.Table_Field_Id = tf.Table_Field_Id
 	 Join Ed_Fieldtypes eft On eft.ED_Field_Type_Id = tf.ED_Field_Type_Id
Where tfv.TableId = 38 and KeyId = @MessageId
Delete From  Email_Message_Data Where Message_id = @MessageId
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @InsertId
