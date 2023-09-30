

CREATE PROCEDURE [dbo].[spLocal_eCIL_SaveQRCodeInfo_TS]	
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_SaveQRCodeInfo_TS
Author				:		Praveen Jain
Date Created		:		21-Dec-2022	
SP Type				:			
Description:
=========
Get the list of task(s) for specific slave units and can be filter by :

CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			21-Dec-2022		Praveen Jain		Creation of SP

*/
		
@RoutesList			VARCHAR(8000)	= NULL,
@TourStopList		VARCHAR(8000)	=NULL,
@QRName				VARCHAR(2000)	,
@QRDesc				VARCHAR(8000)	,
@EntryBy			INT

--WITH ENCRYPTION
AS
SET NOCOUNT ON




--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
--[]																	[]--
--[]							SECTION 1 - Variables Declaration		[]--
--[]																	[]--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--


DECLARE
@QRType			VARCHAR(20),
@CreatedOn			DATETIME

DECLARE @TTourStop TABLE
(
TKey						int IDENTITY(1,1),
TTourStopId						int
)

DECLARE @TQRName TABLE
(
TQRNameKey						int IDENTITY(1,1),
TQRName					varchar(50)
)

DECLARE @TQRDesc TABLE
(
TQRDescKey						int IDENTITY(1,1),
TQRDesc						varchar(255)
)

DECLARE @TempTourStop TABLE
(
TempTourStopKey						int IDENTITY(1,1),
TempTourStopId						int,
TempQRName					varchar(50),
TempQRDesc						varchar(255)
)

INSERT INTO @TTourStop(TTourStopId)
Select string from dbo.fnLocal_STI_Cmn_SplitString(@TourStopList,',')

INSERT INTO @TQRName(TQRName)
Select string from dbo.fnLocal_STI_Cmn_SplitString(@QRName,',')

INSERT INTO @TQRDesc(TQRDesc)
Select string from dbo.fnLocal_STI_Cmn_SplitString(@QRDesc,',')

INSERT INTO @TempTourStop (TempTourStopId,TempQRName,TempQRDesc)
Select TTourStopId,TQRName,TQRDesc from @TTourStop join @TQRName ON TKey=TQRNameKey JOIN @TQRDesc ON TKey=TQRDescKey


DECLARE 
@RowNum INT,
@LastRow INT,
@SecurityExit INT,
@TourStopID1 INT,
@QRName1 varchar(50),
@QRDesc1 varchar(255),
@ErrorMessage varchar(255)


--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]								SECTION 2 - Insert QR Data into table					 []--
--[]																						 []--
--[]  We have receive a list of route, tourstop as parameter.								 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[]--

SET @CreatedOn = GETDATE()
	SET @QRType ='ByTourStop'

SET @RowNum = (SELECT MIN(TempTourStopKey) FROM @TempTourStop)
		SET @LastRow = (SELECT MAX(TempTourStopKey) FROM @TempTourStop)
		SET @SecurityExit = 0	-- This variable is only a security to avoid endless loop

WHILE @RowNum <= @LastRow

		

			BEGIN
				SET @TourStopID1 = NULL
				SET @QRName1 = NULL
				SET @QRDesc1 = NULL
				
				-- Fetch the current row in variables
				SELECT	@TourStopID1 = TempTourStopId,
							@QRName1 = TempQRName,
							@QRDesc1 = TempQRDesc
				FROM		@TempTourStop
				WHERE		TempTourStopKey = @RowNum


				/*Exit SP if there is already Qr code with same name */
IF EXISTS	(
				SELECT	1
				FROM		dbo.Local_PG_eCIL_QRInfo 
				WHERE		QR_Name = @QRName1
				)
	BEGIN
		RAISERROR ( 'There is already a QR with this Name: ' , 16, 1)
		RETURN
	END

			
		INSERT INTO Local_PG_eCIL_QRInfo
		(QR_Name,QR_Description,Route_Ids, Tour_Stop_Id ,QR_Created_On,Entry_By,QR_Type) 
		VALUES(@QRName1 ,@QRDesc1,@RoutesList, @TourStopID1,@CreatedOn,@EntryBy,@QRType); 

		-- Update the task in the database
				

		SET @RowNum = (SELECT MIN(TempTourStopKey) FROM @TempTourStop WHERE (TempTourStopKey > @RowNum))

		-- Security loop exit counter
		SET @SecurityExit = @SecurityExit + 1

		-- After 1000 iterations of the loop, we consider that there is a problem
		-- that could cause an endless loop. We exit.
		IF @SecurityExit > 1000
			BEGIN
				RAISERROR ('Endless loop encountered in WHILE block', -- Message text.
								16, -- Severity.
								1 -- State.
								);
				RETURN

			END
			END

SET NOCOUNT OFF
