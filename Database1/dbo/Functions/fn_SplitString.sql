	CREATE FUNCTION [dbo].[fn_SplitString](@str [nvarchar](max), @Delimiter [nchar](1))
	RETURNS @returnTable Table(	[col1] int NULL)  
	AS 
	Begin
		Insert into @returnTable
		Select Id from dbo.fnCMN_IdListToTable('aaa',@str,@Delimiter)
		Return;
	End
