-- spNP_IDsFromString. Parse the input string(s) for embeded IDs. String uses '$'(dollar sign) for termination and '_' (underscore) for continuation.
--
CREATE PROCEDURE dbo.spNP_IDsFromString 
 	   @String1 	 Varchar(8000)
 	 , @String2 	 Varchar(8000) = NULL
AS
DECLARE @CurrentString 	 Varchar(8000)
DECLARE @i          	 integer
DECLARE @tCharacter 	 char
DECLARE @tString 	 nVarchar(10)
Declare @ItemCount 	 integer
DECLARE @tID 	  	 integer
SELECT @CurrentString = ''
SELECT @tString = ''
CREATE TABLE #Temp_ID (ID integer)
 	 
SELECT @i = 1
Select @ItemCount = 0
SELECT @CurrentString = @String1 	  	     
SELECT @tCharacter = SUBSTRING (@CurrentString, @i, 1)
WHILE ( @tCharacter <> '$' AND @i < 7999 )
  BEGIN
    -- Accumulate digits
    IF @tCharacter <> ',' AND @tCharacter <> '_'
      SELECT @tString = @tString + @tCharacter 	  	 
    -- Character is separator or string continuation symbol
    ELSE
      BEGIN
        SELECT @tString = LTRIM(RTRIM(@tString))
        IF @tString <> '' 
          BEGIN
            SELECT @tID = CONVERT(integer, @tString)
            Select @ItemCount = @ItemCount + 1
            INSERT #Temp_ID VALUES(@tID)
          END
        --End IF @tString <> '' 
        IF @tCharacter = ','            -- separator found
            BEGIN
              SELECT @tString = ''      -- initialize string for next ID
            END
        ELSE -- @tCharacter = '_' string continuation symbol
          BEGIN
            SELECT @tString = ''
            SELECT @CurrentString = @String2
            SELECT @i = 0
          END
        --End IF @tCharacter = ','
      END
    --End IF @tString <> '' 
    SELECT @i = @i + 1
    SELECT @tCharacter = SUBSTRING(@CurrentString, @i, 1)
  END
--End WHILE (@tCharacter <> '$') AND (@i < 7999)
 	  	 
SELECT @tString = LTRIM(RTRIM(@tString))
IF @tString <> '' 
  BEGIN
    SELECT @tID = CONVERT(integer, @tString)
    Select @ItemCount = @ItemCount + 1
    INSERT #Temp_ID VALUES(@tID)
  END
--End IF @tString <> '' 
SELECT * FROM #Temp_Id
Drop Table #Temp_ID
