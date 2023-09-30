
-------------------------------------------------------------------------------
-- This SP populate the sql table when an event that needs to be reported to 
-- the ERP happens
--
-- 13-Jul-2012	Alex Judkwowicz (GEIP)		Initial Development
--
-- Apr 10 2013	Misha Kravcehnko (GEIP)		Added ErrorCode = 0 when inserting the new record into table
-- 06-13-2013 BalaMurugan Rajendran (TCS) Added the correct header / permissions 
-- 07-25-2014 BalaMurugan Rajendran (TCS) Code for MOT Download
-------------------------------------------------------------------------------
/*
exec spLocal_INTInsertRecordForTriggeredEvent 'WorkOrderupdate','brtc-mslab056','2014-08028','','Closing','908484944','eu71','8', '9', '10','11'
*/

CREATE	PROCEDURE	[dbo].[spLocal_CmnWKInsertRecordForTriggeredEvent_Timed]
		@MessageType			VARCHAR(255)	= NULL,
		@Site					VARCHAR(255)	= NULL,
		@Field01				VARCHAR(255)	= NULL,
		@Field02				VARCHAR(255)	= NULL,
		@Field03				VARCHAR(255)	= NULL,
		@Field04				VARCHAR(255)	= NULL,
		@Field05				VARCHAR(255)	= NULL,
		@Field06				VARCHAR(255)	= NULL,
		@Field07				VARCHAR(255)	= NULL,
		@Field08				VARCHAR(255)	= NULL,
		@Field09				VARCHAR(255)	= NULL,
		@Field10				VARCHAR(255)	= NULL,
		@Field11				VARCHAR(255)	= NULL,
		@Field12				VARCHAR(255)	= NULL,
		@Field13				VARCHAR(255)	= NULL,
		@Field14				VARCHAR(255)	= NULL,
		@Field15				VARCHAR(255)	= NULL,
		@Field16				VARCHAR(255)	= NULL,
		@Field17				VARCHAR(255)	= NULL,
		@Field18				VARCHAR(255)	= NULL,
		@Field19				VARCHAR(255)	= NULL,
		@Field20				VARCHAR(255)	= NULL,
		@FlagByPassDispatcher	VARCHAR(255)	= NULL
		
 AS
 


-------------------------------------------------------------------------------
-- Configure environment
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Handle Parameters
-------------------------------------------------------------------------------

 Declare @pp_id int
 Declare @path_id int
 Declare @ppstatusid int
 
 
 SELECT @pp_id = pp_id,
 @path_id = Path_Id,
 @ppstatusid = PP_Status_Id
 FROM Production_Plan WITH (NOLOCK) 
 WHERE Path_id = @Field05 AND PP_Status_Id = 3
 
 
INSERT	dbo.Local_tblINTIntegrationtriggeredevents (MessageType, Field01, Field02,
		Field03, Field04, Field05, Field06, Field07, Field08, Field09, Field10,
		Field11, Field12, Field13, Field14, Field15, Field16, Field17, Field18,
		Field19, Field20, [Site], FlagBypassDispatcher, ErrorCode)
		VALUES	(@MessageType, @Field01, @pp_id, @ppstatusid, @Field04, @path_id,
				@Field06, @Field07, @Field08, @Field09, @Field10, @Field11, 
				@Field12, @Field13, @Field14, @Field15, @Field16, @Field17,
				@Field18, @Field19, @Field20, @Site,
				@FlagByPassDispatcher, 0)
				

SELECT	@@IDENTITY NewRecordID				
				


--GRANT EXECUTE ON [dbo].[spLocal_INTInsertRecordForTriggeredEvent] TO [public]




