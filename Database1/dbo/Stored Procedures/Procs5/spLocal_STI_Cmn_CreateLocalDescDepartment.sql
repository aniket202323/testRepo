
----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_STI_Cmn_CreateLocalDescDepartment]
/*
----------------------------------------------
Stored Procedure:		spLocal_STI_Cmn_CreateLocalDescDepartment
Author:					Alexandre Turgeon, STI
Date Created:			08-June-2009
SP Type:					
Called by:				Manually called, used by RTT Next Gen line configuration
Version:					1.0.0
Editor Tab Spacing:	3

Description:
=========
SP used to enter the local description for a department

Revision 		Date				Who						What
========			=====				====						=====
1.0.0				08-June-2009	Alexandre Turgeon		SP Creation

--------------------------------------------------------------------------------------------------------
TEST CODE :
exec spLocal_STI_Cmn_CreateLocalDescDepartment '', ''
--------------------------------------------------------------------------------------------------------
*/
@DeptDescLocal		varchar(50),
@DeptDescGlobal	varchar(50)

AS

SET NOCOUNT ON

-- verify if department exists
IF NOT EXISTS (SELECT Dept_Id FROM dbo.Departments WHERE Dept_Desc_Global = @DeptDescGlobal)
	BEGIN
		SELECT 'Department ' + @DeptDescGlobal + ' not found.'
		RETURN
	END

-- set department's local description
UPDATE	dbo.Departments
SET		Dept_Desc_Local = @DeptDescLocal
WHERE		Dept_Desc_Global = @DeptDescGlobal

SET NOCOUNT OFF

