CREATE PROCEDURE dbo.spServer_CmnSendEmail
@EG_Id int,
@Subject nvarchar(2000),
@Content varchar(8000),
@TableId int,
@KeyId int
 AS
Insert Into Email_Messages(EG_Id,EM_Subject,EM_Content,Submitted_On,Table_Id,Key_Id) Values(@EG_Id,@Subject,@Content,dbo.fnServer_CmnGetDate(GetUTCDate()),@TableId,@KeyId)
