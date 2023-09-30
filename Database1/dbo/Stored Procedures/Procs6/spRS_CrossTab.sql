CREATE PROCEDURE [dbo].[spRS_CrossTab] 
     @select varchar(8000),
     @sumfunc varchar(100), 
     @pivot varchar(100), 
     @table varchar(100)
AS
SET NOCOUNT ON
SET ANSI_WARNINGS OFF
DECLARE @sql varchar(8000) 
DECLARE @delim varchar(1)
/*
-- Create The Temp Table
EXEC ('SELECT ' + @pivot + ' AS pivot INTO ##MyPivot FROM ' + @table + ' WHERE 1 = 2')
-- Populate Temp Table
EXEC ('INSERT INTO ##MyPivot SELECT DISTINCT ' + @pivot + ' FROM ' + @table + ' WHERE ' + @pivot + ' Is Not Null')
*/
SELECT @sql= '',  
       @sumfunc = stuff(@sumfunc, len(@sumfunc), 1, ' End)' )
Create Table #MyPivot(pivotcol varchar(100))
EXEC ('INSERT INTO #MyPivot SELECT DISTINCT ' + @pivot + ' FROM ' +  @table + ' WHERE ' + @pivot + ' IS NOT NULL')
Select @Delim = ''''
-- This doesn't work 
/*
SELECT @delim=CASE CharIndex('char', data_type)+CharIndex('date', data_type)+CharIndex('varchar', data_type)  
WHEN 0 THEN '' ELSE '''' END 
FROM tempdb.information_schema.columns 
WHERE table_name='##MyPivot' AND column_name='pivot'
*/
select @delim = ''''
Select @sql = @sql + stuff(@sumfunc,charindex( '(', @sumfunc )+1, 0, ' CASE ' + @pivot + ' WHEN ' 
+ @delim + convert(varchar(100), pivotcol) + @delim + ' THEN ' ) + ' AS [' + convert(varchar(100), pivotcol) + '], ' FROM #MyPivot
/*
-- Original Method
SELECT @sql = @sql + '''' + convert(varchar(100), pivot) + ''' = ' + 
stuff(@sumfunc,charindex( '(', @sumfunc )+1, 0, ' CASE ' + @pivot + ' WHEN ' 
+ @delim + convert(varchar(100), pivot) + @delim + ' THEN ' ) + ', ' FROM ##MyPivot
*/
--DROP TABLE ##MyPivot
Drop Table #MyPivot
--pRINT 'BEFORE @SQL = ' + @SQL
SELECT @sql = left(@sql, len(@sql) - 1)
--Select @Select
/*
select @SQL = ' sum( CASE var_desc WHEN ''P1 Calculation Erik'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Calculation Erik] '
select @SQL = @SQL + ', sum( CASE var_desc WHEN ''P1 Pickup Vaccuum'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Pickup Vaccuum]'
select @SQL = @SQL + ', sum( CASE var_desc WHEN ''P1 Headbox pH {x}'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Headbox pH {x}]'
select @SQL = @SQL + ',  sum( CASE var_desc WHEN ''P1 Push Broke Loss'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Push Broke Loss]'
select @SQL = @SQL + ',  sum( CASE var_desc WHEN ''P1 Input 1 Last Value'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Input 1 Last Value]'
*/
SELECT @select = stuff(@select, charindex(' FROM ', @select) + 1, 0, ', ' + @sql + ' ')
--Select @Select
--Select @SQL = Replace(@SQL, '''', '''''')
--Select @select = Replace(@select, '''', '''''')
--PRINT @Select
--select @output = convert(varchar(8000), @Select)
--select @output = 'Select Production_Day , sum( CASE var_desc WHEN ''P1 Calculation Erik'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Calculation Erik], sum( CASE var_desc WHEN ''P1 Pickup Vaccuum'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Pickup Vaccuum], sum( CASE var_desc WHEN ''P1 Headbox pH {x}'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Headbox pH {x}], sum( CASE var_desc WHEN ''P1 Push Broke Loss'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Push Broke Loss], sum( CASE var_desc WHEN ''P1 1st Dryer Draw'' THEN convert(decimal(10,2), Result) EnD) AS [P1 1st Dryer Draw], sum( CASE var_desc WHEN ''P1 Input 1 Last Value'' THEN convert(decimal(10,2), Result) EnD) AS [P1 Input 1 Last Value] From #ProductionVariableData Group By Production_Day'
--return
EXEC (@select)
SET ANSI_WARNINGS ON
