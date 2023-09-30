CREATE PROCEDURE [dbo].[spLocal_joel_test1]
AS
    SET NOCOUNT ON;
    DECLARE @a INT = 2;
    IF (@a=2) GOTO sortie;

    output:
    SELECT 'IN OUTPUT';
    RETURN;

sortie:
	SELECT 'IN SORTIE';

SET NOCOUNT OFF;
RETURN;