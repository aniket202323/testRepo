
CREATE PROCEDURE  [dbo].[spRIS_GetTestsResults] 
	@timestamp NVARCHAR(3999) -- End time of the samples/UDE      
AS 

/*---------------------------------------------------------------------------------------------------------------------
    This procedure returns all tests by comma separated Result_On values
  
    Date         Ver/Build   Author              Story/Defect		Remarks
    31-Dec-2019  001         Bhavani				 US390388			Initial Development (Retrieve test results for a sample.)
	27-Jul-2020  002			 Evgeniy Kim			 F54687				Added SpecDesc to output based on Prod_Id
	31-Jul-2020  003			 Evgeniy Kim			 Bug during test		Fix to ensure samples can be deleted
    02-Sep-2020  004         Evgeniy Kim         US439017           Added sort as per user story
	02-Oct-2020  005			 Evgeniy Kim			 DE144073			Added variable precision to output for Float datatypes
	30-Oct-2020	 006         Evgeniy Kim			 Bug					Material lot tests will always be returned even if spec
																	was updated and/or removed.
	01-Nov-2020	 007			 Evgeniy Kim			 Bug					Fixed issue if more than 1 characteristic is present on product
---------------------------------------------------------------------------------------------------------------------
    NOTES: 
	1. We need the prodId to find the correct specification used with the variables. 
	exec [spRIS_GetTestsResults] '2020-10-30 17:20:57.113,2020-10-30 17:20:57.163,2020-10-30 17:20:58.163'
	exec [spRIS_GetTestsResults_backup10302020] '2020-10-30 17:20:57.113,2020-10-30 17:20:57.163,2020-10-30 17:20:58.163'
	
	QUESTIONS:
	1. Why is Event_Id returned twice in output? No idea
	
---------------------------------------------------------------------------------------------------------------------*/

DECLARE @tResultOn TABLE (
    Result_On DATETIME NOT NULL
);

INSERT INTO @tResultOn SELECT * FROM string_split(@timestamp,',')

DECLARE @appliedProductId INT;

-- Get the product Id first
--SELECT	@appliedProductId = ev.Applied_Product 
--FROM		Tests T
--JOIN		User_Defined_Events UDE WITH(NOLOCK)
--ON		T.Event_Id = UDE.UDE_Id
--JOIN		[Events] ev WITH(NOLOCK)
--ON		ev.Event_Id = UDE.Event_Id
--WHERE	t.Result_On IN (SELECT Result_On FROM @tResultOn); 
Declare @event_Id Varchar(max)
Declare @SQL varchar (max)
 
Select  @appliedProductId  = E.Applied_Product  from User_Defined_Events UDE 
LEFT JOIN  Events E  ON UDE.Event_Id  = E.Event_Id
WHERE 
EXISTS (SELECT 1 FROM @tResultOn WHERE Result_On = UDE.End_Time )


Select @event_Id = COALESCE(@event_Id+',','')+ cast(UDE.UDE_ID as varchar) from User_Defined_Events UDE 
LEFT JOIN  Events E  ON UDE.Event_Id  = E.Event_Id
WHERE 
EXISTS (SELECT 1 FROM @tResultOn WHERE Result_On = UDE.End_Time )
 
SELECT @SQL='SELECT t.Event_Id,t.Test_Id,t.Result,t.canceled,t.Var_Id,t.Comment_Id,t.Result_On FROM Tests t WHERE t.Event_Id in ('+@event_Id+') and Result_On IN ( '''+Replace(@timestamp,',',''',''')+''')';

DECLARE @testResults TABLE (
	SampleId				INT  NULL,
	Test_Id				BIGINT NOT NULL,
	Result				NVARCHAR(25) NULL,
	Canceled				BIT NOT NULL,
	Var_Id				INT NOT NULL,
	Comment_Id			INT NULL,
	Result_On			DATETIME NOT NULL,
	Spec_Desc			NVARCHAR(50) DEFAULT '',
	PU_Groups_PUG_Order	INT NULL,
	PU_Groups_PUG_Desc	NVARCHAR(50) NULL,
	VB_PUG_Order			INT NULL,
	VB_PUG_Id			INT NULL,
	Var_Precision		TINYINT NULL	,
	Char_Id				INT NULL,
	Spec_Id				INT NULL
);

INSERT INTO @testResults (SampleId, Test_Id, Result, Canceled, Var_Id, Comment_Id, Result_On)
EXEC(@SQL)


-- Get variable precision and sort order
UPDATE  T SET T.Var_Precision = VB.Var_Precision,
		T.VB_PUG_Order = VB.PUG_Order,
		T.VB_PUG_Id = VB.PUG_Id
FROM		@testResults T
JOIN		Variables_Base VB WITH(NOLOCK)
ON		T.Var_Id = VB.Var_Id;

-- Get variable group name and sort order
UPDATE	T SET T.PU_Groups_PUG_Order = PG.PUG_Order,
		T.PU_Groups_PUG_Desc = PG.PUG_Desc
FROM		@testResults T
JOIN		PU_Groups PG WITH(NOLOCK)
ON		T.VB_PUG_Id = PG.PUG_Id;

-- Get characteristic found on product
UPDATE	T SET T.Char_Id = PCD.Char_Id
FROM		@testResults T
JOIN		Product_Characteristic_Defaults PCD WITH(NOLOCK)
ON		PCD.Prod_Id = @appliedProductId
JOIN		Product_Properties PP WITH(NOLOCK)
ON		PP.Prop_Id = PCD.Prop_Id
AND		PP.Prop_Desc = N'Receiving and Inspection';

-- Get current active specifications
UPDATE	T SET T.Spec_Id = active_specs.Spec_Id
FROM		@testResults T
JOIN		Active_Specs active_specs WITH(NOLOCK)
ON		T.PU_Groups_PUG_Desc = active_specs.[Target]
AND		T.Char_Id = active_specs.Char_Id
AND		active_specs.Expiration_Date IS NULL;

-- Get specification names
UPDATE	T SET T.Spec_Desc = specs.Spec_Desc
FROM		@testResults T
JOIN		Specifications specs WITH(NOLOCK)
ON		T.Spec_Id = specs.Spec_Id;

SELECT  SampleId AS Event_Id,
		Test_Id,     
		Result,      
		canceled,      
		Var_Id,    
		Comment_Id,  
		Result_On ,  
		SampleId AS sampleID,
		Spec_Desc,
		Var_Precision

FROM @testResults 
ORDER BY PU_Groups_PUG_Order, VB_PUG_Order, VB_PUG_Id, Event_Id;

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON

SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON