CREATE TABLE [dbo].[Local_CTS_Cleaning_Methods] (
    [CCM_id]      INT          IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NOT NULL,
    [Code]        VARCHAR (50) NOT NULL,
    CONSTRAINT [Local_CTS_Cleaning_Methods_PK_CCM_id] PRIMARY KEY CLUSTERED ([CCM_id] ASC)
);

