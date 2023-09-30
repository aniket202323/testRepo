
--------------------------------------------------------------------------------------------------
-- Function: fnLocal_GetFLCode
--------------------------------------------------------------------------------------------------
-- Author				: Shrikant Kalwade
-- Date created			: 2014-06-12
-- Version 				: Version [1.0] 
-- Function Type		: Select
-- Caller				: Custom App
-- Description			: Getting the Fl number as per equipment
--						  
-- Editor tab spacing	: 4
--------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====							=====
-- 1.0			2013-09-16		Shrikant Kalwade						initial release  
-- 1.1			2014-07-25		Alex Judkowicz (GE)						split up the 12 left join
--																		update in indivudal conditional
--																		updates to improve performance
--------------------------------------------------------------------------------------------------
-- LOGIC --this code is for getting the FL number
-- Examples:
-- select @LocationAssignment = 'CN=ee4105dd-d70a-4e1a-b7fd-4d0c2695e39d,CN=56e1aa27-40c4-42c7-a02e-869a7b163c6c,CN=b86ddbf8-3cd7-4975-981d-ba14c23fe62d,CN=77126a24-de03-41a8-821f-d044a622c254,CN=a2089247-6bc6-41b2-8f9b-e249a9ee5859,CN=1f5bbbf0-200c-4c45-afa8-23f4f43e76e7,CN=Instances,CN=Equipment,CN=SOAProject,CN=Projects,OU=Publications,O=Proficy'
-- select @LocationAssignment = 'CN=cdd6f973-1875-455c-b314-9d4155eba965,CN=efaf9d74-7956-4a57-8937-330e0781cb37,CN=a2089247-6bc6-41b2-8f9b-e249a9ee5859,CN=1f5bbbf0-200c-4c45-afa8-23f4f43e76e7,CN=Instances,CN=Equipment,CN=SOAProject,CN=Projects,OU=Publications,O=Proficy'

CREATE FUNCTION [dbo].[fnLocal_GetFLCode]
(
	-- Add the parameters for the function here
	@LocationAssignment nvarchar(max)		--- Task Id
	--@Type varchar(10)		--- Task/TaskStep
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE
		@FLCode varchar(50),
		@StartingPoint int,
		@Length int,
		@Levels int
	--	Initialize Variables
	SELECT
	@StartingPoint = 4,
	@Length = 36,
	@Levels = (LEN(@LocationAssignment)-77)/40
	-- Add the T-SQL statements to compute the return value here
DECLARE @TaskFLCodes TABLE(LocationAssigned nvarchar(max),
					FLLevel int,
					Location varchar(50),
					LFL varchar(25),
					lotype varchar(50),
					Parent1 varchar(50),
					P1FL varchar(25),
					P1Type varchar(50),
					Parent2 varchar(50),
					P2FL varchar(25),
					P2Type varchar(50),
					Parent3 varchar(50),
					P3FL varchar(25),
					P3Type varchar(50),
					Parent4 varchar(50),
					P4FL varchar(25),
					P4Type varchar(50),
					Parent5 varchar(50),
					P5FL varchar(25),
					P5Type varchar(50),
					Parent6 varchar(50),
					P6FL varchar(25),
					P6Type varchar(50)) 

INSERT INTO @TaskFLCodes(LocationAssigned,
					FLLevel,
					Location,
					Parent1 ,
					Parent2 ,
					Parent3 ,
					Parent4 ,
					Parent5 ,
					Parent6)
SELECT @LocationAssignment,
		@Levels,
		SUBSTRING(@LocationAssignment,@StartingPoint,@Length),
		CASE 
			WHEN @Levels > 1 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 40 ,@Length)
		END,
		CASE 
			WHEN @Levels > 2 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 80 ,@Length)
		END,
		CASE 
			WHEN @Levels > 3 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 120 ,@Length)
		END,
		CASE 
			WHEN @Levels > 4 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 160 ,@Length)
		END,
		CASE 
			WHEN @Levels > 5 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 200 ,@Length)
		END,
		CASE 
			WHEN @Levels > 6 THEN SUBSTRING(@LocationAssignment,@StartingPoint + 240 ,@Length)
		END


IF	@Levels >=1
	UPDATE	FC
			SET	LFL		= CONVERT(varchar(25), PEEC.Value),
				LoType	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Location 
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 

IF	@Levels >=2
	UPDATE	FC
			SET	P1FL	= CONVERT(varchar(25), PEEC.Value),
				P1Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent1
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			

IF	@Levels >=3			
	UPDATE	FC
			SET	P2FL	= CONVERT(varchar(25), PEEC.Value),
				P2Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent2
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			

IF	@Levels >=4			
	UPDATE	FC
			SET	P3FL	= CONVERT(varchar(25), PEEC.Value),
				P3Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent3
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			

IF	@Levels >=5			
	UPDATE	FC
			SET	P4FL	= CONVERT(varchar(25), PEEC.Value),
				P4Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent4
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			

IF	@Levels >=6			
	UPDATE	FC
			SET	P5FL	= CONVERT(varchar(25), PEEC.Value),
				P5Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent5
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			

IF	@Levels >=7			
	UPDATE	FC
			SET	P6FL	= CONVERT(varchar(26), PEEC.Value),
				P6Type	= EQP.[Type]
				FROM	@TaskFLCodes FC
				JOIN	dbo.Property_Equipment_EquipmentClass PEEC	(NOLOCK) 
				ON		PEEC.EquipmentId = FC.Parent6
				AND		PEEC.Name = 'PGSAPEquipmentLinkage'
				JOIN	dbo.Equipment EQP							(NOLOCK) 
				ON		EQP.EquipmentId = PEEC.EquipmentId 
			
/*		
UPDATE @TaskFLCodes SET
LFL = CONVERT(varchar(25), peec1.Value),
P1FL = CONVERT(varchar(25), peec2.Value),
P2FL = CONVERT(varchar(25), peec3.Value),
P3FL = CONVERT(varchar(25), peec4.Value),
P4FL = CONVERT(varchar(25), peec5.Value),
P5FL = CONVERT(varchar(25), peec6.Value),
P6FL = CONVERT(varchar(25), peec7.Value),
lotype = eqp1.Type,
P1Type = eqp2.Type,
P2Type=eqp3.Type,
P3Type=eqp4.Type,
P4Type= eqp5.Type,
P5Type= eqp6.Type,
P6Type = eqp7.Type


FROM @TaskFLCodes fc
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec1 (NOLOCK) ON peec1.EquipmentId = fc.Location AND peec1.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec2 (NOLOCK) ON peec2.EquipmentId = fc.Parent1 AND peec2.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec3 (NOLOCK) ON peec3.EquipmentId = fc.Parent2 AND peec3.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec4 (NOLOCK) ON peec4.EquipmentId = fc.Parent3 AND peec4.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec5 (NOLOCK) ON peec5.EquipmentId = fc.Parent4 AND peec5.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec6 (NOLOCK) ON peec6.EquipmentId = fc.Parent5 AND peec6.Name = 'PGSAPEquipmentLinkage'
LEFT JOIN dbo.Property_Equipment_EquipmentClass peec7 (NOLOCK) ON peec7.EquipmentId = fc.Parent6 AND peec7.Name = 'PGSAPEquipmentLinkage'

LEFT JOIN dbo.Equipment eqp1 (nolock) on eqp1.EquipmentId = peec1.EquipmentId and peec1.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp2 (nolock) on eqp2.EquipmentId = peec2.EquipmentId and peec2.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp3 (nolock) on eqp3.EquipmentId = peec3.EquipmentId and peec3.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp4 (nolock) on eqp4.EquipmentId = peec4.EquipmentId and peec4.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp5 (nolock) on eqp5.EquipmentId = peec5.EquipmentId and peec5.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp6 (nolock) on eqp6.EquipmentId = peec6.EquipmentId and peec6.Name ='PGSAPEquipmentLinkage'
LEFT JOIN dbo.Equipment eqp7 (nolock) on eqp7.EquipmentId = peec7.EquipmentId and peec7.Name ='PGSAPEquipmentLinkage'
*/

SELECT @FLCode = 
	CASE
		WHEN (ISNULL(P6FL,'') + '-') = '-' THEN ''
		ELSE P6FL + '-'
	END +
	CASE
		WHEN (ISNULL(P5FL,'') + '-') = '-' or P6Type = 'ProductionLine' THEN ''
		ELSE P5FL + '-'
	END +
	CASE
		WHEN (ISNULL(P4FL,'') + '-') = '-' or P5Type = 'ProductionLine' THEN ''
		ELSE P4FL + '-'
	END +
	CASE
		WHEN (ISNULL(P3FL,'') + '-') = '-' or P4Type = 'ProductionLine' THEN ''
		ELSE P3FL + '-'
	END +
	CASE
		WHEN (ISNULL(P2FL,'') + '-') = '-' or P3Type = 'ProductionLine' THEN ''
		ELSE P2FL + '-'
	END +
	CASE
		WHEN (ISNULL(P1FL, '') + '-') = '-' or P2Type = 'ProductionLine' THEN ''
		ELSE P1FL + '-'                                   
	END +
	
	CASE
		WHEN (ISNULL(LFL, '') + '-') = '-' or P1Type = 'ProductionLine' THEN ''
		ELSE LFL
	END
	
	
FROM @TaskFLCodes

	-- Return the result of the function
	return CASE  WHEN RIGHT(@FLCode,1)='-' THEN LEFT(@FLCode,DATALENGTH(@FLCode)-1)
				ELSE 
				@FLCode
				END


END




