 
 
 
CREATE 	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetDispense]
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@KitEventId	INT
AS	
 
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Gets the list of dispense events attached to the selected kit via geneology link
/*
select event_id from events where event_num='K01-905045975-28'
 
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetDispense @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 170180
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 08-JUN-2016	001		001		Chris Donnelly (GE Digital)  Initial development	
-- 13-JUL-2017	001		002		Susan Lee (GE Digital)		 Update location of dispense container as carrier location
-- 29-AUG-2018  002     001     Susan Lee (GE Digital)		 Solving duplicate dispenses in the list by breaking up the joins
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
 
DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	DispenseEventId			INT					NULL,	--Event ID of dispense 
	Dispense				VARCHAR(50)			NULL,	--Event Num of dispense event
	DispensePUId			INT					NULL,	--Dispense PU Id
	Material				VARCHAR(50)			NULL,	--Prod code of dispense event
	Qty						INT					NULL,	--Initial_DimensionX of dispense event
	UOM						VARCHAR(50)			NULL,	--UOM event variable
	[Status]				VARCHAR(50)			NULL,	--Status of dispense event
	CarrierSection			VARCHAR(50)			NULL,	--Carrier section event num (carrier section event num is prefixed with carrier event num)
	CarrierSectionEventId	INT					NULL,	--Carrier section event id
	Location				VARCHAR(50)			NULL	--Location of dispense event num
)
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Get dispense events attached to the selected kit
-------------------------------------------------------------------------------
INSERT INTO @tOutput
	(
		DispenseEventId,
		Dispense,
		DispensePUId,
		Material,
		Qty,
		--UOM,
		[Status]--,
		--CarrierSection,
		--Location
		)
SELECT 
		de.Event_Id				as DispenseEventId,
		de.Event_Num			as Dispense,
		de.PU_Id				as DispensePUId,
		p.Prod_Code				as Material,
		ded.Final_Dimension_X	as Qty,
		--t.Result				as UOM,
		ps.ProdStatus_Desc		as [Status]--,
		--cse.Event_Num			as CarrierSection,
		--ul.Location_Code		as Location
	FROM dbo.[Events]					ke											--Kit Event
		JOIN dbo.Event_Components		ec	ON ec.Event_Id = ke.Event_Id			--G-Link Kit to Parent Dispense
		JOIN dbo.[Events]				de	ON de.Event_Id = ec.Source_Event_Id		--Dispense Event
		JOIN dbo.Event_Details			ded ON ded.Event_ID = de.Event_Id			--Dispense Event Details
		LEFT JOIN dbo.Products_Base		p	ON p.Prod_Id = de.Applied_Product		--Applied Product of Dispense Event
		JOIN dbo.Production_Status ps	ON ps.ProdStatus_Id = de.Event_Status	--Dispense Event Status
		--LEFT JOIN dbo.Variables_Base	v	ON v.PU_Id = de.PU_Id AND v.Var_Desc = 'Dispense UOM'
		--LEFT JOIN dbo.Tests				t	ON t.Var_Id = v.Var_Id AND t.Event_Id = de.Event_Id	--Dispense UOM Variable
		--LEFT JOIN dbo.Event_Components	csec ON csec.Source_Event_Id = ke.Event_Id	--G-Link Kit to Child Carrier Section
		--LEFT JOIN dbo.[Events]			cse	ON cse.Event_Id = csec.Event_Id			--Carrier Section Event
		--LEFT JOIN dbo.Prod_Units_Base	cspu ON cspu.pu_id = cse.pu_id AND cspu.Equipment_Type = 'Carrier Section'
		--LEFT JOIN dbo.Event_Components	c_cs ON c_cs.Event_Id = cse.Event_Id
		--LEFT JOIN dbo.[Events]			c	ON	c.Event_Id = c_cs.Source_Event_Id
		--JOIN dbo.Prod_Units_Base	cpu ON cpu.PU_Id = c.PU_Id AND cpu.Equipment_Type = 'Carrier' 
		--JOIN dbo.Event_Details		ced	ON ced.Event_Id = c.Event_Id
		--LEFT JOIN dbo.Unit_Locations	ul	ON ul.Location_Id = ced.Location_Id		--Dispense Location
	WHERE 
		ke.Event_Id = @KitEventId
 
------- get dispense UOM -------------
UPDATE o
SET UOM = t.Result				
FROM @tOutput o
	JOIN dbo.Variables_Base	v	ON v.PU_Id = o.DispensePUId AND v.Var_Desc = 'Dispense UOM'
	JOIN dbo.Tests				t	ON t.Var_Id = v.Var_Id AND t.Event_Id = o.DispenseEventId	--Dispense UOM Variable
 
------ get carrier section -----------------
UPDATE o
SET CarrierSection = cse.Event_Num,
	CarrierSectionEventId = cse.Event_Id
FROM @tOutput o
		JOIN dbo.Event_Components	csec ON csec.Source_Event_Id = o.DispenseEventId	--G-Link Kit to Child Carrier Section
		JOIN dbo.[Events]			cse	ON cse.Event_Id = csec.Event_Id			--Carrier Section Event
		JOIN dbo.Prod_Units_Base	cspu ON cspu.pu_id = cse.pu_id AND cspu.Equipment_Type = 'Carrier Section'
 
------ get carrier location  ---------
UPDATE o
SET Location = ul.Location_Code
FROM @tOutput o
	JOIN dbo.Event_Components	c_cs ON c_cs.Event_Id = o.CarrierSectionEventId
	JOIN dbo.[Events]			c	ON	c.Event_Id = c_cs.Source_Event_Id
	JOIN dbo.Prod_Units_Base	cpu ON cpu.PU_Id = c.PU_Id AND cpu.Equipment_Type = 'Carrier' 
	JOIN dbo.Event_Details		ced	ON ced.Event_Id = c.Event_Id
	LEFT JOIN dbo.Unit_Locations	ul	ON ul.Location_Id = ced.Location_Id		--Dispense Location
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------
 
SELECT	DISTINCT
		Dispense,
		Material,
		Qty,
		UOM,
		[Status],
		CarrierSection,
		Location
	FROM @tOutput 
	ORDER BY Dispense
 
 
 
 
 
 
