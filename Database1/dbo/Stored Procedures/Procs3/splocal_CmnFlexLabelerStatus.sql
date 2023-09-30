

CREATE PROCEDURE [dbo].[splocal_CmnFlexLabelerStatus] 
		@Line				VARCHAR(255)
AS
------------------------------------------------------------------------------
-- This SP returns the labeler status
--
--
-- Date         Version Build  Author                  Notes
-- 15-Aug-2016  001     001    Alex Judkowicz         Initial development
/*
 exec splocal_CmnFlexLabelerStatus 'BC Line 4'
*/
-------------------------------------------------------------------------------
--Initial settings
-------------------------------------------------------------------------------
SET NOCOUNT ON
-------------------------------------------------------------------------------
-- Declare Variables
-------------------------------------------------------------------------------
DECLARE @tOutput TABLE
(
	[Id]		int		identity(1,1) not null,
	[Line] [nvarchar](2) NULL,
	[Path_Code] [nvarchar](4) NULL,
	[Mode_Auto] [bit] NULL,
	[Mode_Half] [bit] NULL,
	[Mode_Manually] [bit] NULL,
	[PO_Labler] [int] NULL,
	[Last_Update_RSLinx] [datetime] NULL,
	[PO_Proficy] [int] NULL,
	[Labler_Status] [nvarchar](100) NULL,
	[Last_Update_Proficy] [datetime] NULL,
	[Mode_Auto_String] nvarchar(255) NULL,
	[Mode_Half_String] nvarchar(255) NULL,
	[Mode_Manually_String] nvarchar(255) NULL
)    

-------------------------------------------------------------------------------
-- Populate local table (Site specific)
-------------------------------------------------------------------------------
INSERT	@tOutput (Mode_Auto, Mode_Half, Mode_Manually) 
		VALUES (0, 0, 0)
-------------------------------------------------------------------------------
-- Return output
-------------------------------------------------------------------------------

SELECT	[Line]					Line,
		[Path_Code]				Path_Code,
		[Mode_Auto]				Mode_Auto,
		[Mode_Half]				Mode_Half,
		[Mode_Manually]			Mode_Manually,
		[PO_Labler]				PO_Labler,
		[Last_Update_RSLinx]	Last_Update_RSLinx,
		[PO_Proficy]			PO_Proficy,
		[Labler_Status]			Labler_Status,
		[Last_Update_Proficy]	Last_Update_Proficy,
		[Mode_Auto_String]		Mode_Auto_String,
		[Mode_Half_String]		Mode_Half_String,
		[Mode_Manually_String]	Mode_Manually_String
		FROM	@tOutput 
		ORDER
		BY		Id

