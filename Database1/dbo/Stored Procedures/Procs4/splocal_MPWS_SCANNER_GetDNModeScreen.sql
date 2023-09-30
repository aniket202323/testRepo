 
 
CREATE  PROCEDURE [dbo].[splocal_MPWS_SCANNER_GetDNModeScreen]
@ScnnerRowType int,
@ScannerSequenceCount int /* To keep track of key press and show the screen*/
AS
IF @ScannerSequenceCount = 62	
	Select * from dbo.Local_MPWS_ScannerMode where ((MenuSequence IN (61,62,63)) AND (ModeMenu != ''))
ELSE IF (@ScannerSequenceCount = 67)
	SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,68)) AND (ModeMenu != ''))
ELSE
	BEGIN
	IF @ScnnerRowType = 4
	BEGIN
		if @ScannerSequenceCount < 30   
			SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode where ModeMenu != ''
		else if (@ScannerSequenceCount >= 30  AND @ScannerSequenceCount < 60)	
			SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 40)  AND (sm.ModeMenu != ''))	    			
		else if (@ScannerSequenceCount >= 60 AND @ScannerSequenceCount < 90 AND @ScannerSequenceCount <> 66)
			SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 70) AND (sm.ModeMenu != ''))
		ELSE IF (@ScannerSequenceCount = 66)
			SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,67)) AND (ModeMenu != ''))				
		else if @ScannerSequenceCount >= 90
			SELECT * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence = 100)AND (sm.ModeMenu != ''))	
	END
	ELSE IF @ScnnerRowType = 5
	BEGIN
		IF @ScannerSequenceCount < 40
			SELECT top (@ScnnerRowType - 1) * FROM dbo.Local_MPWS_ScannerMode WHERE ModeMenu != ''
		ELSE IF (@ScannerSequenceCount >= 40  AND @ScannerSequenceCount < 80 AND @ScannerSequenceCount <> 66)
			SELECT top (@ScnnerRowType - 2) * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 50) AND (sm.ModeMenu != ''))		
		ELSE IF (@ScannerSequenceCount = 66)
			SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,66,67))AND (ModeMenu != ''))
		ELSE IF @ScannerSequenceCount >= 80 
			SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence IN(90,100)) AND (sm.ModeMenu != ''))
	END
END
 
 
--SELECT top (4 - 1) * from ScannerMode sm where sm.MenuSequence >= 40  
 
