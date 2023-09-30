CREATE TABLE [dbo].[Local_MPWS_GENL_ESigActionData] (
    [ESigActionDataId]      INT              IDENTITY (1, 1) NOT NULL,
    [ESigActionConfigId]    INT              NOT NULL,
    [ElectronicSignatureId] UNIQUEIDENTIFIER NOT NULL,
    [ESigActionData]        VARCHAR (250)    NULL,
    CONSTRAINT [PK_Local_MPWS_GENL_ESigActionData] PRIMARY KEY CLUSTERED ([ESigActionDataId] ASC)
);

