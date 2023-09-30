

CREATE	PROCEDURE [dbo].[spLocal_MPWS_KIT_GetCarrierSections_saved_20170208]
--DECLARE
		@ErrorCode		INT				OUTPUT,
		@ErrorMessage	VARCHAR(500)	OUTPUT,
		@CarrierEventId	INT=NULL,
		@LevelIn        VARCHAR(10)=NULL,
		@RowIn			VARCHAR(10)=NULL,
		@SectionIn		VARCHAR(10)=NULL       
		
AS	

SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Get the list of carrier Sections for the Carrier (Event ID) Passed in
/*
declare @ErrorCode INT, @ErrorMessage VARCHAR(500)
exec spLocal_MPWS_KIT_GetCarrierSections @ErrorCode OUTPUT, @ErrorMessage OUTPUT, 96731
select @ErrorCode, @ErrorMessage
*/
-- Date         Version Build Author  
-- 08-JUN-2016	001		001		Chris Donnelly	(GE Digital)  Initial development	
-- 16-JUN-2016	001		001		Chaitanya		(GE Digital)  Added inputs to SP for Filtering
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------

DECLARE	@tOutput			TABLE
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	CarrierSectionEvent_Id	INT					NULL,
	CarrierStatusId			INT					NULL,
	[Level]					INT					NULL,
	Section					VARCHAR(50)			NULL,
	Kit						VARCHAR(50)			NULL
)


CREATE	TABLE #KitOutput			
(
	Id						INT					IDENTITY(1,1)	NOT NULL,
	[Level]					VARCHAR(10)			NULL,
	[Row]                   VARCHAR(10)			NULL,
	Section					VARCHAR(10)			NULL,
	Section_Actual          VARCHAR(50)         NULL,
	Kit						VARCHAR(50)			NULL,
	CarrierEventId          INT                 NULL,
	CarrierSectionEventId   INT                 NULL,
	CarrierStatusId			INT					NULL
)


DECLARE @SQL VARCHAR(1000),
        @Flag INT=0
        
------------------------------------------------------------------------------
--  Initialize output values
-------------------------------------------------------------------------------
SELECT	@ErrorCode		=	1,
		@ErrorMessage	=	'Success'
-------------------------------------------------------------------------------
-- Get carrier section events
-------------------------------------------------------------------------------
INSERT INTO @tOutput
(CarrierSectionEvent_Id,CarrierStatusId,[Level],Section)
	SELECT cse.Event_Id as CarrierSectionEvent_Id, cse.Event_Status as CarrierStatusId, CHARINDEX (LEFT(RIGHT(cse.Event_Num,3),1),'ABCDEFGHIJKL') as [Level],cse.Event_Num
	FROM dbo.[Events] ce
		JOIN dbo.Event_Components ec on ec.Source_Event_Id = ce.Event_Id
		JOIN dbo.[Events] cse ON cse.Event_Id = ec.Event_Id
	WHERE 
		ce.Event_Id =  @CarrierEventId	

UPDATE t
	SET t.Kit = ke.Event_Num
			FROM 
				@tOutput t
				JOIN dbo.Event_Components kec on kec.Event_Id = t.CarrierSectionEvent_Id	--G-Link Carrier Section to Kit
				JOIN dbo.[Events] ke ON ke.Event_Id = kec.Source_Event_Id	--Kit
				JOIN dbo.Prod_Units_Base p on p.PU_Id = ke.PU_Id AND p.PU_Desc LIKE '%Kit%'
				
-- Copy @toutput results to #kitoutput				
INSERT INTO #KitOutput	
(Kit,Section_Actual,CarrierStatusId,CarrierSectionEventId)	
SELECT kit,Section,CarrierStatusId,CarrierSectionEvent_Id FROM  @tOutput		
				
-- Split the Section num into Levels,Row and Section
UPDATE #KitOutput
SET [Level]= Left(RIGHT(Section_Actual,3),1),
[Row]=  Left(RIGHT(Section_Actual,2),1),
Section=  Left(RIGHT(Section_Actual,1),1),
CarrierEventId = @CarrierEventId	
	

-- Build Dynamic Query to get Levels  with Filters(if any Passed)
SET @SQL = 'select Distinct [Level],CarrierEventId from #KitOutput k'

IF LEN(@LevelIn) > 0 
BEGIN
SET @Flag=1
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
END
-- Execute Dynamic Query
EXECUTE(@SQL) 


-- Build Dynamic Query to get distinct Rows with Filters(if any Passed)
SET @SQL = 'select Distinct [Row],[Level],CarrierEventId from #KitOutput k'
IF @Flag=1
BEGIN
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
END

IF LEN(@RowIn) > 0 
BEGIN

	IF @Flag=1
	BEGIN
	SET @SQL=@SQL+ ' AND k.Row='+ '''' + @RowIn + ''''
	SET @Flag=12
    END
    ELSE
    BEGIN
    SET @SQL=@SQL+ ' WHERE k.Row='+ '''' + @RowIn + ''''
    SET @Flag=2
    END
END
-- Execute Dynamic Query
EXECUTE(@SQL) 

-- Build Dynamic Query to get distinct Sections with Filters(if any Passed)
SET @SQL = 'select Distinct Section,[Row],[Level],CarrierEventId from #KitOutput k'
IF @Flag=1
BEGIN
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
END

IF @Flag=2
BEGIN
SET @SQL=@SQL+ ' WHERE k.Row='+ '''' + @RowIn + ''''
END

IF @Flag=12
BEGIN
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
SET @SQL=@SQL+ ' AND k.Row='+ '''' + @RowIn + ''''
END


IF LEN(@SectionIn) > 0 
BEGIN
	IF @Flag=0
	BEGIN
	SET @SQL=@SQL+ ' WHERE k.Section='+ '''' + @SectionIn + ''''
    END
	ELSE
    BEGIN
    SET @SQL=@SQL+ ' AND k.Section='+ '''' + @SectionIn + ''''
    END
END
-- Execute Dynamic Query
EXECUTE(@SQL) 
 
 
 
 --Build Dynamic Query to get distinct Sections,kits  with Filters(if any Passed)
SET @SQL = 'select Distinct Section,[Row],[Level],CarrierEventId,CarrierSectionEventId,CarrierStatusId,Section_Actual,Kit from #KitOutput k'
IF @Flag=1
BEGIN
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
END

IF @Flag=2
BEGIN
SET @SQL=@SQL+ ' WHERE k.Row='+ '''' + @RowIn + ''''
END

IF @Flag=12
BEGIN
SET @SQL=@SQL+ ' where k.Level='+'''' + @LevelIn + ''''
SET @SQL=@SQL+ ' AND k.Row='+ '''' + @RowIn + ''''
END


IF LEN(@SectionIn) > 0 
BEGIN
	IF @Flag=0
	BEGIN
	SET @SQL=@SQL+ ' WHERE k.Section='+ '''' + @SectionIn + ''''
    END
	ELSE
    BEGIN
    SET @SQL=@SQL+ ' AND k.Section='+ '''' + @SectionIn + ''''
    END
END    
-- Execute Dynamic Query    
EXECUTE(@SQL) 
	
-- Drop temporary Table
DROP TABLE #KitOutput				
------------------------------------------------------------------------------
-- Return Data Table
-------------------------------------------------------------------------------

--SELECT	[Level]			[Level],
--		Section			Section,	
--		Kit				Kit
--	FROM @tOutput 

--GRANT EXECUTE ON [dbo].[spLocal_MPWS_KIT_GetCarrierSections] TO [public]

