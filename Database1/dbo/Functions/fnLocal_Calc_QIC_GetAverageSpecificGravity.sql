CREATE FUNCTION [dbo].[fnLocal_Calc_QIC_GetAverageSpecificGravity]
(@url NVARCHAR (MAX) NULL, @company NVARCHAR (50) NULL, @business NVARCHAR (50) NULL, @gcas NVARCHAR (20) NULL, @lookback INT NULL, @numEntries INT NULL)
RETURNS DECIMAL (18, 9)
AS
 EXTERNAL NAME [FortechQic].[Fortech.Qic.Clr.SqlFunctions].[GetAverageSpecificGravity]

