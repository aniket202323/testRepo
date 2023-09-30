

/*Step B Creation Of SP*/
CREATE  PROCEDURE [dbo].spLocal_BDAT_GetBatchHistoryLineDetails

/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_BDAT_GetBatchHistoryLineDetails
Author				:		Pratik Patil
Date Created		:		09-12-2023
SP Type				:		BDAT
Editor Tab Spacing  :       3
	
Description:
=========
This Stored procedure will provide details of batchhistory lines configured a site and whether the join batch is configured or not.

CALLED BY:  BDAT Tool
Revision 		Date			Who					   What
========		=====			====				   =====
1.0.0			12-SEP-2023	    Pratik Patil		   Creation of SP
Test Code:
EXEC spLocal_BDAT_GetBatchHistoryLineDetails
*/

@Yes varchar(10) = 'Yes',
@No  varchar(10) = 'No',
@NA  varchar(10) =  'NA'

AS
DECLARE @FinalResult TABLE(Line_name	varchar(255),
						Path_code		varchar(255),
						JoinBatch		varchar(255));

INSERT INTO @FinalResult(Line_name, Path_code)
	select pl_desc, pep.Path_Code from table_fields_values tfv (NOLOCK)
	join Table_Fields tf (NOLOCK) on tf.Table_Field_Id = tfv.Table_Field_Id 
	join tables t (NOLOCK) on t.TableId = tf.TableId 
	join prdexec_paths pep (NOLOCK) on pep.Path_Id = tfv.keyid
	join Prod_Lines_Base pl on pl.pl_id = pep.pl_id 
	where Table_Field_Desc like 'PE_BachHistoryPendingCancel' and value = '1' order by PL_Desc ; 

	
IF  EXISTS(SELECT table_field_id FROM dbo.Table_Fields WHERE Table_Field_Desc = 'Is_BatchhistoryMaterialMovement' )

BEGIN
update FR SET JoinBatch = @Yes
	from @FinalResult FR
	JOIN (select pl_desc, Value from table_fields_values tfv (NOLOCK)
	join Table_Fields tf (NOLOCK) on tf.Table_Field_Id = tfv.Table_Field_Id 
	join tables t (NOLOCK) on t.TableId = tf.TableId 
	join prdexec_paths pep (NOLOCK) on pep.Path_Id = tfv.keyid
	join Prod_Lines_Base pl on pl.pl_id = pep.pl_id 
	where Table_Field_Desc like 'Is_BatchhistoryMaterialMovement' and value in (309,310,311)) t on t.pl_desc = fr.Line_name;
END
update FR SET JoinBatch = @No
	from @FinalResult FR where JoinBatch is NULL;

select * from @finalResult;

