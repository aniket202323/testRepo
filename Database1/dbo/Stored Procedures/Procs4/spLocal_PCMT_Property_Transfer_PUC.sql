













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Transfer_PUC]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 5.0.0 (P3 and P4)
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_Property_Transfer_PUC
Author:					Rick Perreault(STI)
Date Created:			05-Feb-04
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
Return the variable list that do not have the corresponding spec in the new property.
PCMT Version 2.1.0 and 3.0.0

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who								What
========	===========	==========================	===============================================================
1.2.0		23-May-06	Marc Charest (STI)			RTT groups are now split across multiple units.
																We revisited the SP to take care of these changes.
1.1.0		03-Nov-05	Normand Carbonneau (STI)	Compliant with Proficy 3 and 4.
																Added [dbo] template when referencing objects.
																Added registration of SP Version into AppVersions table.
																PCMT Version 5.0.3
*/
@intPropId			integer,
@intPuId				integer

AS

SET NOCOUNT ON

DECLARE
@intMasterPUID		INTEGER

SET @intMasterPUID = (SELECT ISNULL(master_unit, pu_id) FROM dbo.Prod_Units WHERE pu_id = @intPuId)

SELECT	pp.prop_desc, pl.pl_desc, slave.pu_desc AS [Unit], 
			CASE WHEN pu.pu_desc = slave.pu_desc THEN ' ' ELSE pu.pu_desc END AS [Master], 
			p.prod_desc, c.char_desc
FROM dbo.PU_Products pup
     JOIN dbo.Products p ON p.prod_id = pup.prod_id 
     JOIN dbo.Prod_Units pu ON pu.pu_id = pup.pu_id
	  JOIN dbo.Prod_Units slave ON ISNULL(slave.master_unit, slave.pu_id) = pu.pu_id and slave.pu_id = @intPuId
	  JOIN dbo.Prod_lines pl ON pl.pl_id = pu.pl_id
     LEFT JOIN dbo.PU_Characteristics puc ON puc.pu_id = pup.pu_id AND
                                             puc.prod_id = pup.prod_id AND
                                             puc.prop_id = @intPropId
	  JOIN dbo.Product_Properties pp ON puc.prop_id = pp.prop_id
     LEFT JOIN dbo.Characteristics c ON c.char_id = puc.char_id
WHERE pup.pu_id = @intMasterPUID

SET NOCOUNT OFF















