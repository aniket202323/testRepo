
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateGlobalDescDepartment]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateGlobalDescDepartment
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the Global description for a department

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateGlobalDescDepartment '', ''
--------------------------------------------------------------------------------------------------------
*/
@DeptDescGlobal	varchar(50),
@DeptDescLocal		varchar(50)

AS

SET NOCOUNT ON

-- verify if department exists
IF NOT EXISTS (SELECT Dept_Id FROM dbo.Departments WHERE Dept_Desc_Local = @DeptDescLocal)
	BEGIN
		SELECT 'Department ' + @DeptDescLocal + ' not found.'
		RETURN
	END

-- set department's Global description
UPDATE	dbo.Departments
SET		Dept_Desc_Global = @DeptDescGlobal
WHERE		Dept_Desc_Local = @DeptDescLocal

SET NOCOUNT OFF

