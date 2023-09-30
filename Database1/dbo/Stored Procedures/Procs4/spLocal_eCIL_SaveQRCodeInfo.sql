
CREATE PROCEDURE [dbo].[spLocal_eCIL_SaveQRCodeInfo]	
/*
-------------------------------------------------------------------------------------------------
Stored Procedure	:		spLocal_eCIL_SaveQRCodeInfo
Author				:		Payal Gadhvi
Date Created		:		21-Dec-2022
SP Type				:		eCIL	
Description:
=========
Save QR Code information for any QR_Type 
CALLED BY:  eCIL Web Application
Revision 		Date			Who						What
========		=====			====					=====
1.0.0			21-Dec-2022		Payal Gadhvi			Creation of SP
1.0.1			02-Feb-2023		Megha Lohana			Updated to grant permissions to role instead of local user
1.0.2	        03-Apr-2023     Aniket B				Code clean up per new coding standards.  
1.0.3			19-Apr-2023		Payal Gadhvi			Removed QRId as Output parameter, removed QR_Created_On from INSERT
1.0.4			27-Apr-2023		Payal Gadhvi			Added an upsert operations to the AppVersions table that does a single scan on an update and does 2 for insert
1.0.5 			03-May-2023     Aniket B			    Remove grant permissions statement from the SP as moving it to permissions grant script

Test Code :
EXEC spLocal_eCIL_SaveQRCodeInfo NULL , '122' , NULL , NULL , 'QRNameForTourStop1' , NULL , 1
*/		
@LinesList			VARCHAR(8000)	= NULL,
@RoutesList			VARCHAR(8000)	= NULL,
@TourStopList		VARCHAR(8000)	=NULL,
@VarIdList			VARCHAR (max)   =NULL,
@QRName				VARCHAR(8000),
@QRDesc				VARCHAR(8000)	=NULL,
@EntryBy			INT
AS
SET NOCOUNT ON;

/*[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--
--[]																	[]--
--[]							SECTION 1 - Variables Declaration		[]--
--[]																	[]--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][]--*/

DECLARE @QRType	VARCHAR(20);

SET @QRName = LTRIM(RTRIM(@QRName));

IF @QRDesc IS NOT NULL
		SET @QRDesc = LTRIM(RTRIM(@QRDesc));
	
/*[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[][]--
--[]																						 []--
--[]								SECTION 2 - Insert QR Data into table					 []--
--[]																						 []--
--[][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][][[]*/

IF @LinesList IS NOT NULL AND @VarIdList IS NOT NULL AND @LinesList <> ''
	BEGIN
		IF EXISTS	(
				SELECT	1
				FROM		dbo.Local_PG_eCIL_QRInfo 
				WHERE		QR_Name = @QRName AND QR_Type LIKE '%Task'
				)
			BEGIN ;
				THROW 50001, 'There is already a QR code with this Name.', 1 ;
				RETURN;
			END

			SET @QRType = 'ByLineTask';

			INSERT INTO dbo.Local_PG_eCIL_QRInfo
			(QR_Name,QR_Description,Line_Ids,Var_Ids,Entry_By,QR_Type) 
			VALUES(@QRName,@QRDesc,@LinesList,@VarIdList,@EntryBy,@QRType); 
			RETURN ;
	END

IF @RoutesList IS NOT NULL AND @VarIdList IS NOT NULL AND @RoutesList <> ''
	BEGIN
		IF EXISTS	(
				SELECT	1
				FROM		dbo.Local_PG_eCIL_QRInfo 
				WHERE		QR_Name = @QRName AND QR_Type LIKE '%Task'
				)
			BEGIN ;
				THROW 50001, 'There is already a QR code with this Name.', 1;  
				RETURN;
			END

		SET @QRType = 'ByRouteTask';

		INSERT INTO dbo.Local_PG_eCIL_QRInfo
		(QR_Name,QR_Description,Route_Ids,Var_Ids,Entry_By,QR_Type) 
		VALUES(@QRName,@QRDesc,@RoutesList,@VarIdList,@EntryBy,@QRType); 
		RETURN ;				
	END

IF @RoutesList IS NOT NULL AND @VarIdList IS NULL AND @TourStopList IS NULL
	BEGIN
	IF EXISTS	(
				SELECT	1
				FROM		dbo.Local_PG_eCIL_QRInfo 
				WHERE		QR_Name = @QRName AND QR_Type = 'ByRoute'
				)
			BEGIN ;
				THROW 50001, 'There is already a QR code with this Name.', 1 ; 
				RETURN;
			END

		SET @QRType = 'ByRoute';

		INSERT INTO dbo.Local_PG_eCIL_QRInfo
		(QR_Name,QR_Description,Route_Ids,Entry_By,QR_Type) 
		VALUES(@QRName,@QRDesc,@RoutesList,@EntryBy,@QRType);
		RETURN ;		
	END

IF @TourStopList IS NOT NULL AND @RoutesList IS NOT NULL
	BEGIN
			IF EXISTS	(
				SELECT	1
				FROM		dbo.Local_PG_eCIL_QRInfo 
				WHERE		QR_Name = @QRName AND QR_Type = 'ByTourStop' AND  Route_Ids = @RoutesList
				)
			BEGIN ;
				THROW 50001, 'There is already a QR code with this Name.', 1 ;  
				RETURN;
			END
		SET @QRType = 'ByTourStop';

		/* declare temporary table to separate string */
		DECLARE @QR AS TABLE(QR_Name VARCHAR(50),QR_Desc VARCHAR(255) NULL,TourStopId INT);
		
		INSERT INTO @QR(QR_Name,QR_Desc,TourStopId)
		SELECT  qn.String, CASE WHEN qd.String = '' THEN NULL ELSE qd.String END,cast (ts.String as int)
		FROM dbo.fnLocal_STI_Cmn_SplitString(@qrname,',') AS qn JOIN dbo.fnLocal_STI_Cmn_SplitString(@qrdesc,',') AS qd  ON qn.id=qd.id
		JOIN dbo.fnLocal_STI_Cmn_SplitString(@TourStopList,',') AS ts  ON qn.id=ts.id;
		
		/*transfer all qr codes from temporary table to the main table */
		INSERT INTO dbo.Local_PG_eCIL_QRInfo
		(QR_Name,QR_Description,Route_Ids,Tour_Stop_Id,Entry_By,QR_Type) 
		SELECT q.QR_Name,q.QR_Desc,@RoutesList,q.TourStopId,@EntryBy,@QRType FROM @QR q;
		RETURN ;			
	END
