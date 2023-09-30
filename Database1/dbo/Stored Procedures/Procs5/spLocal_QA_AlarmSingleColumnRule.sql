

CREATE PROCEDURE dbo.spLocal_QA_AlarmSingleColumnRule
/*
Stored procedure: spLocal_QA_AlarmSingleColumnRule
Revision date who what
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-10-27
Version		:	4.0.1
Description	: 	Changed the way to retreive the sheet_id
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-10-03
Version		:	4.0.0
Description	: 	Renamed SP to have a more descriptive name
-------------------------------------------------------------------------------------------------
used to be splocal_QA_TAMU_Nbr_U
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2006-09-07
Version		:	3.0.0
Purpose		: 	Added an input that indicates the minimum number of U to look for
-------------------------------------------------------------------------------------------------
Altered By	:	Alexandre Turgeon (System Technologies for Industry Inc)
Date			:	2005-11-17
Version		:	2.1.0
Purpose		: 	Compliant with Proficy 3 and 4.
					Added [dbo] template when referencing objects.
					Added registration of SP Version into AppVersions table.
					PSMT Version 4.0.0
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by Ugo Lapierre, Solutions et Technologies Industrielles inc.
On 8-Mar-05							Version 2.0.1
Purpose : 		When getting var_id in temps table, avoid using PU_ID and
					specify the display ID
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Altered by Ugo Lapierre, Solutions et Technologies Industrielles inc.
On 18-Nov-04							Version 2.0.0
Purpose : 		Trigger on ZPV_Check_data_Entry and verify value.
------------------------------------------------------------------------------------------------------------------------------------------------------------------
Author			: 	Ugo Lapierre, Solutions et Technologies Industrielles inc.
Date created 	:	29-Oct-04							
Version 			:	1.0.0
Description 	:	Verify for TAMU alarm rule A
Editor tab spacing: 3
Called by		:	Calculated variable
SP Type			:	Function
------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
@OutputValue 		varchar(30) OUTPUT,
@dteTimestamp 		datetime,
@intVar_id			int,
@strEI				varchar(30),
@intMax				int

AS
DECLARE
@intPUID				int,
@strResult			varchar(5),
@intNbrU				int,
@intSheet_id		int,
@intDependancyId	int,
@strDependancyVal	varchar(30)

DECLARE @Tamu_U TABLE (
	var_id1 int,
	result1 int)

SET NOCOUNT ON

IF @strEI IS NULL
BEGIN
	SET @OutputValue = ''
	SET NOCOUNT OFF
	RETURN
END

--get the dependancy varibales id and the value
SET @intDependancyId = (SELECT var_id FROM dbo.calculation_dependency_data WHERE result_var_id = @intVar_id)

SET @strDependancyVal = (SELECT result FROM dbo.tests WHERE var_id = @intDependancyId AND result_on = @dteTimestamp)

IF @strDependancyVal <> 'OK, data complete'
BEGIN
	SET NOCOUNT OFF
	RETURN
END

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'splocal_QA_TAMU_Nbr_U','Info','Sp_started ' + convert(varchar(30),@dteTimestamp,20))

--Find the PU_id of the units WHERE TAMU is on
SET @intPUID = (SELECT pu_id FROM dbo.variables WHERE var_id = @intVar_id)

--Find sheet_id from alarm variable
SET @intSheet_id = (SELECT sheet_id 
						  FROM dbo.sheet_variables
						  WHERE var_id = @intVar_id)

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'splocal_QA_TAMU_Nbr_U','@intSheet_id',convert(varchar(30),@intSheet_id))

INSERT INTO @Tamu_U (var_id1) 
  (SELECT sv.var_id 
   FROM dbo.variables v
     JOIN dbo.sheet_variables sv ON v.var_id = sv.var_id 
   WHERE v.extended_info LIKE '%' + @strEI + '%' AND sv.sheet_id = @intSheet_id)

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'splocal_QA_TAMU_Nbr_U','Info','After table ' )

UPDATE @Tamu_U 
SET result1 = CONVERT(int, t.result)
	FROM @tamu_u x, dbo.tests t
	WHERE x.var_id1 = t.var_id AND t.result_on = @dteTimestamp

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'splocal_QA_TAMU_Nbr_U','Info','After update table ' )

SET @intNbrU = (SELECT COUNT(result1) FROM @Tamu_U WHERE result1 >= @intMax)

--insert sti_test(entry_on,sp_name,parameter,value) values(getdate(),'splocal_QA_TAMU_Nbr_U','Max U',@intMax )

SET @OutputValue = CONVERT(int, @intNbrU)

SET NOCOUNT OFF


