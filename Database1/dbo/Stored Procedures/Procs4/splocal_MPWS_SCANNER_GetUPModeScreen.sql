 
 
 
 
CREATE  PROCEDURE [dbo].[splocal_MPWS_SCANNER_GetUPModeScreen]
@ScnnerRowType int,
@ScannerSequenceCount int /* To keep track of key press and show the screen*/
AS
if @ScnnerRowType = 4
BEGIN
	if @ScannerSequenceCount <= 40   
		SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode where ModeMenu != ''
	else if @ScannerSequenceCount = 63
		SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 61) AND (sm.ModeMenu != '')) Order By sm.MenuSequence ASC
	else if (@ScannerSequenceCount = 66)
			SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,66)) AND (ModeMenu != ''))	
	else if (@ScannerSequenceCount = 67)
			SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,67)) AND (ModeMenu != ''))	
	else if (@ScannerSequenceCount > 40  AND @ScannerSequenceCount <= 70)	
	    SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 40) AND (sm.ModeMenu != ''))
	else if @ScannerSequenceCount > 70  AND @ScannerSequenceCount <= 90 
		SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 70) AND (sm.ModeMenu != ''))
		
END
else if @ScnnerRowType = 5
BEGIN
	if @ScannerSequenceCount <= 50   
		SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode where ModeMenu != ''
	else if @ScannerSequenceCount = 63
		SELECT top (@ScnnerRowType - 2) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 61) AND (sm.ModeMenu != '')) Order By sm.MenuSequence ASC
	else if ((@ScannerSequenceCount = 67) or (@ScannerSequenceCount = 68))
			SELECT * FROM dbo.Local_MPWS_ScannerMode WHERE ((MenuSequence IN (64,65,66,67)) AND (ModeMenu != ''))	
	else if @ScannerSequenceCount > 50  and @ScannerSequenceCount <= 90
		SELECT top (@ScnnerRowType - 2) * from dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= 50) AND (sm.ModeMenu != ''))
	else if @ScannerSequenceCount > 90 
		SELECT top (@ScnnerRowType - 1) * from dbo.Local_MPWS_ScannerMode sm where ((sm.Id = 9 OR sm.Id = 35) AND (sm.ModeMenu != ''))
END
RETURN 0
 
 
 
--SELECT top (4 - 1) * from dbo.Local_MPWS_ScannerMode sm where sm.MenuSequence >= 40  
 
 
 
