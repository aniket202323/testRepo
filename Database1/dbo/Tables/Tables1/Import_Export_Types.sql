CREATE TABLE [dbo].[Import_Export_Types] (
    [First_Required_Data_Column] INT          NULL,
    [IE_Type_Desc]               VARCHAR (50) NOT NULL,
    [IE_Type_Id]                 INT          NOT NULL,
    [Import_Order]               INT          NOT NULL,
    [Is_Trans_Needed]            BIT          NOT NULL,
    [Is_Type_Needed]             INT          NULL,
    CONSTRAINT [ImportExportTypes_PK_IETypeId] PRIMARY KEY CLUSTERED ([IE_Type_Id] ASC)
);

