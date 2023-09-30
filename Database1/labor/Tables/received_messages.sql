CREATE TABLE [labor].[received_messages] (
    [consumer_id]   VARCHAR (450) NOT NULL,
    [message_id]    VARCHAR (450) NOT NULL,
    [creation_time] BIGINT        NULL,
    CONSTRAINT [PK_received_messages] PRIMARY KEY CLUSTERED ([consumer_id] ASC, [message_id] ASC)
);

