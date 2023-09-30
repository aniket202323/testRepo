
CREATE  PROCEDURE  [dbo].[spLocal_eCIL_CreateUDEs] (@UDEStartTime DATETIME, @UDEEndTime DATETIME, @MasterPUID INT)
/*
SQL Proceedure			:		spLocal_eCIL_CreateUDEs
Author					:		TCS
Date Created			:		10-March-2020
Editor Tab Spacing	    :		3
Description:
===========
Creates UDEs
CALLED BY				:  SP
Revision 	Date			Who						What
========	===========		==================		=================================================================================
1.0		10-March-2020		Megha Lohana			Created SP
1.0.1		23-Jan-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.2		03-March-2022		Megha Lohana			Updated to the latest coding standards
1.0.3		09-Mar-2023		Payal Gadhvi			Added condition to check PA version for spServer_DBMgrUpdUserEvent SP parameter
1.0.4		10-July-2023		Aniket B			Updated version mangement and code clean up as per coding standard
TEST CODE :
SELECT dbo.spLocal_eCIL_CreateUDEs(995, '2020-01-18 06:30:00.000', '2020-01-25 06:30:00.000' )
*/

AS
SET NOCOUNT ON

BEGIN

DECLARE

@UDEStartTimeString		varchar(25),
@UDENum					varchar(1000),
@EventSubtypeDesc       varchar(100), 
@Now                    DATETIME,
@EventSubType           int,
@UDEId					int,
@UserId                 int,
@Conformance		tinyInt,
@TestPctComplete	tinyInt;


		SET @UDEStartTimeString = convert(varchar(25), @UDEStartTime, 120);
		SET @UDENum = CONVERT(varchar(30), @UDEStartTime, 20) + '-Shiftly eCIL';
		SET @UserId = (SELECT [User_Id] FROM dbo.Users WITH(NOLOCK) WHERE UserName = 'eCILSystem');
		SET	@EventSubtypeDesc = (SELECT event_subtype_desc from event_subtypes where event_subtype_desc like 'eCIL');
        SET @EventSubType = (SELECT event_subtype_id from event_subtypes where event_subtype_desc like 'eCIL');
		SET @Now = (SELECT GETDATE())

IF (SELECT CONVERT(FLOAT,LEFT(app_version,3))  from dbo.appversions with (nolock) WHERE app_name LIKE '%DatabaseMGR%') > 7
BEGIN	

		EXEC dbo.spServer_DBMgrUpdUserEvent 
				0,										/*-- *Transaction Number  0=Update fields that are not null 2=Update all fields */
				@EventSubtypeDesc,						/*-- *Event Subtype Desc */
				NULL,									/*-- Action Comment Id */
				NULL,									/*-- Action 4 */
				NULL,									/*-- Action 3 */
				NULL,									/*-- Action 2 */
				NULL,									/*-- Action 1 */
				NULL,									/*-- Cause Comment Id */
				NULL,									/*-- Cause 4 */
				NULL,									/*-- Cause 3 */
				NULL,									/*-- Cause 2 */
				NULL,									/*-- Cause 1 */
				@UserId,								/*-- Ack By */
				1,										/*-- *Ack */
				NULL,									/*-- Duration */
				@EventSubType,							/*-- *Event Subtype Id */
				@MasterPUID,							/*-- *Pu Id */
				@UDENum,								/*-- *Ude Desc */
				@UDEId OUTPUT,							/*-- *Ude Id */
				@UserId,								/*-- *User Id */
				@Now,									/*-- Ack On */
				@UDEStartTime,							/*-- *Start Time */
				@UDEEndTime,							/*-- *End Time */
				NULL,									/*-- Research Comment Id */
				NULL,									/*-- Research Status Id */
				NULL,									/*-- Research User Id */
				NULL,									/*-- Research Open Date */
				NULL,									/*-- Research Close Date */
				1,										/*-- *Transtype */
				NULL,									/*-- UDE Comment Id */
				NULL,									/*-- Event Reason Tree Data Id */
				NULL,									/*--SignatureId */
				NULL,									/*--EventId */
				NULL,									/*--ParentUDEId */
				NULL,									/*--Event_Status */
				NULL,									/*--TestingStatus */
				@Conformance OUTPUT,					/*--Conformance */
				@TestPctComplete OUTPUT,				/*--TestPctComplete */
				1,										/*--ReturnResultSet 1=return resultset, 2= Defer resultset */
				NULL;									/*--FriendlyDesc */

		/*-- Create the event on the unit for the path */
		       SELECT   8,						/*-- UDE Resultset */
					0,							/*-- Pre=1 Post=0 */
					@UDEId,						/*-- User Defined Event Id  */
					@UDENum,					/*-- User_Defined_Events Desc */
					@MasterPUID,				/*-- Unit Id */
					@EventSubType,				/*-- Event Subtype Id */
					@UDEStartTime,				/*-- Start Time */
					@UDEEndTime,				/*-- End Time */
					NULL,						/*-- Duration */
					1,							/*-- Acknowledged */
					@Now,						/*-- Ack Timestamp */
					@UserId,					/*-- Acknowledged By */
					NULL,						/*-- Cause 1 */
					NULL,						/*-- Cause 2 */
					NULL,						/*-- Cause 3 */
					NULL,						/*-- Cause 4 */
					NULL,						/*-- Cause Comment Id */
					NULL,						/*-- Action 1 */
					NULL,						/*-- Action 2 */
					NULL,						/*-- Action 3 */
					NULL,						/*-- Action 4 */
					NULL,						/*-- Action Comment Id */
					NULL,						/*-- Research User Id */
					NULL,						/*-- Research Status Id */
					NULL,						/*-- Research Open Date */
					NULL,						/*-- Research Close Date */
					NULL,						/*-- Research Comment Id */
					NULL,						/*-- Comments (Comment_Id) */
					1,							/*-- Transaction Type  1=Add 2=Update 3=Delete */
					@EventSubtypeDesc,			/*-- Event Sub Type Desc */
					2,							/*-- Transaction Number  0=Update fields that are not null 2=Update all fields */
					@UserId	;					/*-- User Id */
					
END
ELSE
BEGIN
					
		EXEC dbo.spServer_DBMgrUpdUserEvent 
				0,										/*-- *Transaction Number  0=Update fields that are not null 2=Update all fields  */
				@EventSubtypeDesc,					/*-- *Event Subtype Desc */
				NULL,									/*-- Action Comment Id */
				NULL,									/*-- Action 4 */
				NULL,									/*-- Action 3 */
				NULL,									/*-- Action 2 */
				NULL,									/*-- Action 1 */
				NULL,									/*-- Cause Comment Id */
				NULL,									/*-- Cause 4 */
				NULL,									/*-- Cause 3 */
				NULL,									/*-- Cause 2 */
				NULL,									/*-- Cause 1 */
				@UserId,								/* Ack By */
				1,										/*-- *Ack */
				NULL,									/*-- Duration */
				@EventSubType,							/*-- *Event Subtype Id */
				@MasterPUID,							/*-- *Pu  */
				@UDENum,								/*-- *Ude Desc */
				@UDEId OUTPUT,							/*-- *Ude Id */
				@UserId,								/*-- *User Id */
				@Now,									/*-- Ack On */
				@UDEStartTime,							/*-- *Start Time  */
				@UDEEndTime,							/*-- *End Time */
				NULL,									/*-- Research Comment Id */
				NULL,									/*-- Research Status Id */
				NULL,									/*-- Research User Id */
				NULL,									/*-- Research Open Date */
				NULL,									/*-- Research Close Date */
				1,										/*-- *Transtype */
				NULL,									/*-- UDE Comment Id */
				NULL,									/*-- Event Reason Tree Data Id */
				NULL,									/*--SignatureId */
				NULL,									/*--EventId */
				NULL,									/*--ParentUDEId */
				NULL,									/*--Event_Status */
				NULL,									/*--TestingStatus */
				@Conformance OUTPUT,							/*--Conformance */
				@TestPctComplete OUTPUT,						/*--TestPctComplete */
				1	;								/*--ReturnResultSet 1=return resultset, 2= Defer resultset */
				

		/*-- Create the event on the unit for the path  */
		       SELECT   8,					-- UDE Resultset */
					0,						-- Pre=1 Post=0 */
					@UDEId,					-- User Defined Event Id */
					@UDENum,					-- User_Defined_Events Desc */
					@MasterPUID,					-- Unit Id */
					@EventSubType,			-- Event Subtype Id */
					@UDEStartTime,			-- Start Time */
					@UDEEndTime,				-- End Time */
					NULL,						-- Duration */
					1,							-- Acknowledged */
					@Now,					-- Ack Timestamp */
					@UserId,				-- Acknowledged By */
					NULL,						-- Cause 1 */
					NULL,						-- Cause 2 */
					NULL,						-- Cause 3 */
					NULL,						-- Cause 4 */
					NULL,						-- Cause Comment Id */
					NULL,						-- Action 1 */
					NULL,						-- Action 2 */
					NULL,						-- Action 3 */
					NULL,						-- Action 4 */
					NULL,						-- Action Comment Id */
					NULL,						-- Research User Id */
					NULL,						-- Research Status Id */
					NULL,						-- Research Open Date */
					NULL,						-- Research Close Date */
					NULL,						-- Research Comment Id */
					NULL,						-- Comments (Comment_Id) */
					1,							-- Transaction Type  1=Add 2=Update 3=Delete */
					@EventSubtypeDesc,			-- Event Sub Type Desc */
					2,							-- Transaction Number  0=Update fields that are not null 2=Update all fields */
					@UserId	;					-- User Id */
	END			

END
    
