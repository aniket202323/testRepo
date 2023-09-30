
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].spLocal_Util_UDE_Creation
/*
----------------------------------------------
Stored Procedure:		spLocal_Util_CreateUDE
Author:					Ugo Lapierre (STI)
Date Created:			11-Apr-06
SP Type:					Calculation
Called by:				ASP page sending value in variables
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
This SP is triggered when an ASPx page sent dipslay name, the timestamp and UDE num to the input variable.
It creates an user define event.  This will be used for manula inserted column.

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				11-Apr-06		Ugo Lapierre			SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
DECLARE
@OutputValue varchar(25)
exec spLocal_Util_CreateUDE @OutputValue output,'RTT Shiftly Manual EA2 CSA001','15-May-06 17:01',150, 'test-111'
select @OutputValue

--------------------------------------------------------------------------------------------------------
*/
@OutputValue 			varchar(25) OUTPUT,
@intDisplay				int,
@strEndtime				varchar(25),
@strUDENum				varchar(50),
@intPUID_Calc			int

AS
SET NOCOUNT ON
DECLARE
@intEventSubtype			int,
@intPUID						int,
@strCaller					varchar(30),
@dteEndtime					datetime,
@strSPname					varchar(50),
@strEvent_Subtype_Desc	varchar(50),
@strQuery					varchar(200),
@RSUserId					int,
@dteStartTime				datetime



/*-----------------------------------------------------------------------------------------------
Get event subtype and pu_id from the display name
Verify if the display exist and if the display is user_define event type
if not, exit the SP
-----------------------------------------------------------------------------------------------*/
SELECT 	@intEventSubtype = event_subtype_id,
			@intPUID = master_unit
FROM DBO.sheets
WHERE sheet_id = @intDisplay AND sheet_type = 25  --25 = autolog user_define events

IF @intEventSubtype IS NULL	
BEGIN
--This is not a valid display or the display is not UDE autolog
	SELECT @OutputValue = 'Invalid display'
	SET NOCOUNT OFF
	RETURN
END


/*-----------------------------------------------------------------------------------------------
Verify if the time is a valid timestamp.  If not,exit
check if there is already an event at that time, if yes exit.
-----------------------------------------------------------------------------------------------*/
IF ISDATE(@strEndtime)=0
BEGIN
	SELECT @OutputValue = 'Invalid DATE format'
	SET NOCOUNT OFF
	RETURN
END
ELSE
BEGIN
	SET @dteEndtime = convert(datetime,@strEndtime)
	IF EXISTS(SELECT UDE_ID FROM DBO.user_defined_events WHERE event_subtype_id = @intEventSubtype AND pu_id = @intPUID AND end_time = @dteEndtime)
	BEGIN
--There is already an event at that time, get out
		SELECT @OutputValue = 'Column already exist'
		SET NOCOUNT OFF
		RETURN				
	END
END


/*--------------------------------------------------------------------------------------------------
verify for specific SP for the event subtype.
If there is a UPD of the name of the event subtype on the unit, it should return the SP name to use.
Cretate the UDE
--------------------------------------------------------------------------------------------------*/
--Get event subtype desc
SELECT @strEvent_Subtype_Desc = Event_Subtype_Desc
FROM DBO.event_subtypes
WHERE Event_Subtype_id = @intEventSubtype

--Get spname
SELECT @strSPname = tfv.value
FROM dbo.table_fields_values tfv
JOIN dbo.table_fields tf ON tfv.table_field_id = tf.table_field_id
JOIN dbo.tables t ON tfv.tableid = t.tableid
WHERE t.tablename = 'Prod_units' AND tf.table_field_desc = @strEvent_Subtype_Desc
AND tfv.keyid = @intPUID_Calc

IF @strSPname IS NOT NULL
BEGIN
--Use SP to created UDE
	SET @strquery = @strSPname + ' ''Manual'',' + convert(varchar(10),@intPUID)
  	SET @strquery = @strquery + ',' + convert(varchar(50),@intEventSubtype) + ',''' + convert(varchar(30),@dteEndtime,20)+''''
	EXEC (@strquery)
	SELECT @OutputValue = 'UDE CREATED with SP'
END
ELSE
BEGIN
--Create UDE with result sets

	SELECT @RSUserId = ISNULL(user_id,26) FROM DBO.users WHERE username = 'RTTSystem'
	SET @dteStartTime = @dteEndtime

	SELECT 8, 1, null, @strUDENum, @intPuid, @intEventSubType, @dteStartTime, @dteEndtime, 
	null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, 
	null, null, null, null, null, 1, null, 2, @RSUserId

	SELECT @OutputValue = 'UDE CREATED with RS'
END

SET NOCOUNT OFF

