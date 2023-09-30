CREATE PROCEDURE [dbo].[spLocal_CmnMobileAppGetSubscriptionUDPValue]
	@SubscriptionDesc	varchar(255),
	@TableFieldDesc		varchar(50)
 

AS
SET NOCOUNT ON

DECLARE	
@TableId			int,
@SPName				varchar(50),
@ErrMsg				varchar(25),
@SubscriptionId		int,
@tfId				int


SET @SPName = 'spLocal_CmnMobileAppGetSubscriptionUDPValue'


--1) Get the Tableid 
SET @TableId  = (SELECT TableId from dbo.Tables WITH(NOLOCK) WHERE tableName = 'Subscription')

SET @tfId = (SELECT Table_Field_Id FROM dbo.Table_Fields WITH(NOLOCK) WHERE Table_Field_Desc = @TableFieldDesc AND TableId = @TableId);

--Output
SELECT tfv.Value
FROM dbo.Table_Fields_Values AS tfv WITH(NOLOCK)
JOIN dbo.Subscription AS s			WITH(NOLOCK) ON s.Subscription_Id = tfv.KeyId
WHERE	tfv.Table_Field_Id = @tfId
		AND s.Subscription_Desc = @SubscriptionDesc


SET NOCOUNT OFF
RETURN