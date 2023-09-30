













-------------------------------------------------------------------------------------------------

----------------------------------------[Creation Of SP]-----------------------------------------
CREATE PROCEDURE [dbo].[spLocal_PCMT_Property_Transfer_2]
/*
---------------------------------------------------------------------------------------------------------------
											      PCMT Version 5.0.0 (P3 and P4)
---------------------------------------------------------------------------------------------------------------
Stored Procedure:		spLocal_PCMT_Property_Transfer_2
Author:					Rick Perreault(STI)
Date Created:			05-Feb-04
SP Type:					PCMT
Editor Tab Spacing:	3

Description:
===============================================================================================================
Attach product to characteistics of the new property for the unit of the given production groups.
PCMT Version 2.1.0 and 3.0.0

Called by:  			PCMT (VBA modules)
	
Revision	Date			Who								What
========	===========	==========================	===============================================================
1.3.0		23-May-06	Marc Charest (STI)			RTT groups are now split across multiple units.
																We revisited the SP to take care of these changes.
1.2.0		03-Nov-05	Normand Carbonneau (STI)	Compliant with Proficy 3 and 4.
																Added [dbo] template when referencing objects.
																Added registration of SP Version into AppVersions table.
																Replaced #NewSpecs temp table by @NewSpecs TABLE variable.
																PCMT Version 5.0.3
1.1.0		01-Nov-04	Marc Charest (STI)			We do not want to remove the already attached specifications 
																when these are not found into the target property. So one 
																removed the LEFT JOIN from the first SP query.
																PCMT Version 2.1.0 and 3.0.0
1.0.1		12-May-04	Rick Perreault (STI)			All modifications (Update,Insert,Delete) are done to all the 
																variables at the same time instead of using a cursor and do it 
																by variable.
*/
@intPropId		integer,
@intPugId		integer

AS
SET NOCOUNT ON

DECLARE
@intVarId		integer,
@vcrSpecDesc	varchar(50),
@intSpecId		integer,
@dtmNow 			datetime

DECLARE @NewSpecs TABLE
(
Var_Id			integer,
Pu_Id				integer,
New_Spec_Id		integer
)

SET @dtmNow = getdate()
WAITFOR DELAY '00:00:01'

INSERT @NewSpecs
SELECT v.var_id, v.pu_id, s2.spec_id
FROM dbo.Variables v
     JOIN dbo.Specifications s1 ON s1.spec_id = v.spec_id AND
                                   s1.prop_id <> @intPropId
     JOIN dbo.Specifications s2 ON s2.spec_desc = s1.spec_desc AND
                                   s2.prop_id = @intPropId  
WHERE v.pug_id = @intPugId


--Update the spec id
UPDATE dbo.Variables
	SET spec_id = ns.new_spec_id
	FROM @NewSpecs ns
	WHERE Variables.var_id = ns.var_id

--Delete var_specs > than now  
DELETE FROM dbo.Var_Specs
WHERE var_id IN (SELECT var_id
                 FROM @NewSpecs) AND
      effective_date >= @dtmNow

--Set the expiration date of the current var spec
UPDATE dbo.Var_Specs 
SET expiration_date = @dtmNow, as_id = NULL
WHERE var_id IN (SELECT var_id
                 FROM @NewSpecs) AND
      effective_date < @dtmNow AND
      ISNULL(expiration_date, GETDATE()) > @dtmNow
   
--Update variable specs with active specs.
INSERT 
INTO dbo.Var_Specs(Var_Id,Prod_Id,Effective_Date,Expiration_Date, 
                   L_Entry,L_Reject,L_Warning,L_User,Target,U_User,
                   U_Warning,U_Reject,U_Entry,Test_Freq,Comment_Id,AS_Id)
SELECT ns.Var_Id,puc.Prod_Id,
       Effective_Date = CASE
                          WHEN acs.Effective_Date < @dtmNow THEN @dtmNow
                          ELSE acs.Effective_Date
                        END,
       acs.Expiration_Date,acs.L_Entry,acs.L_Reject,acs.L_Warning,
       acs.L_User,acs.Target,acs.U_User,acs.U_Warning,acs.U_Reject,

       acs.U_Entry,acs.Test_Freq,acs.Comment_Id,acs.AS_Id
FROM @NewSpecs ns 
	  JOIN dbo.Prod_Units pu ON ns.pu_id = pu.pu_id
     JOIN dbo.PU_Characteristics puc ON puc.pu_id = ISNULL(pu.master_unit, pu.pu_id)
     JOIN dbo.Active_Specs acs ON acs.spec_id = ns.new_spec_id AND
                                  acs.char_id = puc.char_id AND
                                  ISNULL(expiration_date, GETDATE()) > @dtmNow
WHERE ns.new_spec_id IS NOT NULL
SET NOCOUNT OFF















