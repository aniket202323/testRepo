 
 
CREATE  PROCEDURE [dbo].[splocal_MPWS_SCANNER_GetF2ModeScreen]
@ScannerSequenceCount int,
@ScnnerRowType int /* To keep track of key press and show the screen*/
AS
 
IF @ScannerSequenceCount > 0 and @ScannerSequenceCount <= 100 
	BEGIN 
	IF 	@ScannerSequenceCount = 60 
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence > @ScannerSequenceCount AND sm.MenuSequence < (@ScannerSequenceCount + 4) ) AND (sm.ModeMenu != ''))
	ELSE IF ((@ScannerSequenceCount = 63 OR @ScannerSequenceCount = 62) AND @ScnnerRowType = 4)
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence  IN (64,65,66)) AND (sm.ModeMenu != ''))
	ELSE IF ((@ScannerSequenceCount = 63 OR @ScannerSequenceCount = 62) AND @ScnnerRowType = 5)
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence  IN (64,65,66,67)) AND (sm.ModeMenu != ''))
	ELSE IF (@ScannerSequenceCount = 66 OR @ScannerSequenceCount = 67 OR @ScannerSequenceCount = 68)
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence = 69) AND (sm.ModeMenu != '')) 
	ELSE IF (@ScannerSequenceCount = 110) --KANBAN
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence IN (111)) AND (sm.ModeMenu != ''))
	ELSE IF (@ScannerSequenceCount = 111) --KANBAN RESTOCK
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence IN (113,114)) AND (sm.ModeMenu != ''))
	--ELSE IF (@ScannerSequenceCount = 112) --KANBAN SHOP
	--	SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence IN (115,116)) AND (sm.ModeMenu != ''))
	ELSE 
		SELECT * FROM dbo.Local_MPWS_ScannerMode sm where ((sm.MenuSequence >= @ScannerSequenceCount and sm.MenuSequence < (@ScannerSequenceCount + 10)) AND (sm.ModeMenu != ''))
	END
ELSE
SELECT TOP (@ScnnerRowType - 1) * FROM dbo.Local_MPWS_ScannerMode sm where sm.ModeMenu != ''
 
RETURN 0
 
 
 
