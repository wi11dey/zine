// Automatically generated from IPDL
// DO NOT EDIT

use async_trait::async_trait;
use serde::{Serialize, Deserialize};
use std::collections::HashMap;
use std::error::Error;
use std::sync::Arc;
use tokio::sync::{mpsc, oneshot};
use tokio::task;

pub mod mozilla {
    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub enum TestProtocolMessage {
        Hello(String),
        GetValue(i32),
        // Note: GetValue requires oneshot:Sender<GetValueResponse> for responses
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct GetValueResponse {
        pub value: String,
    }

    #[async_trait]
    pub trait TestProtocolHandler: Send + Sync {
        async fn handle_hello(&mut self, message: String) -> Result<(), Box<dyn Error + Send + Sync>>;
        async fn handle_get_value(&mut self, id: i32) -> Result<String, Box<dyn Error + Send + Sync>>;
    }

    pub struct TestProtocolActor<H: TestProtocolHandler> {
        handler: H,
        rx: mpsc::Receiver<TestProtocolMessage>,
        tx: mpsc::Sender<TestProtocolMessage>,
    }

    impl<H: TestProtocolHandler> TestProtocolActor<H> {
        pub fn new(handler: H) -> (Self, mpsc::Sender<{protocol_name}Message>) {
            let (tx, rx) = mpsc::channel(100);
            let actor = Self {
                handler,
                rx,
                tx: tx.clone(),
            };
            (actor, tx)
        }

        pub async fn run(mut self) {
            while let Some(msg) = self.rx.recv().await {
                match msg {
                    Hello(message) => {
                        if let Err(e) = self.handler.handle_hello(message).await {
                            eprintln!("Error handling Hello: {:?}", e);
                        }
                    }
                    GetValue(id) => {
                        match self.handler.handle_get_value(id).await {
                            Ok(result) => {
                                // Send response back via channel
                            }
                            Err(e) => {
                                eprintln!("Error handling GetValue: {:?}", e);
                            }
                        }
                    }
                }
            }
        }
    }

}