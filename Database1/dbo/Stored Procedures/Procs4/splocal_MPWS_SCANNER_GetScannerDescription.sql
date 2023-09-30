 
 
 
CREATE  PROCEDURE [dbo].[splocal_MPWS_SCANNER_GetScannerDescription]
		@ErrorCode		INT				OUTPUT		,
		@ErrorMessage	VARCHAR(500)	OUTPUT		
AS
SET NOCOUNT ON
 
SELECT * from dbo.Local_MPWS_ScannerDescription
 
SET		@ErrorMessage	=	'Success'
SET		@ErrorCode	=	1
 
 
