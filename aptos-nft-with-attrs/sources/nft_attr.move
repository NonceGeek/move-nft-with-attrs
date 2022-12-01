module my_addr::nft_attr {

   use std::error;
   use aptos_framework::signer;
   use aptos_framework::account;
   use std::string::{String};

   use aptos_std::event::{Self, EventHandle};
   use aptos_std::table::{Self, Table};

   #[test_only]
   use std::string::{Self};

   const EINVALID_OWNER: u64 = 1;
   const EINVALID_ATTR_ID: u64 = 2;

   struct CreateAttrEvent has drop, store {
      id: u64,
      description: String,
      level: u64,
      additional: String
   }

   struct UpdateAttrEvent has drop, store {
      id: u64,
      description: String,
      level: u64,
      additional: String
   }

   struct Attrs has key {
      attrs: Table<u64, Attr>,
      create_attr_events: EventHandle<CreateAttrEvent>,
      update_attr_events: EventHandle<UpdateAttrEvent>
   }

   struct Attr has store, copy, key {
      id: u64,
      description: String,
      level: u64,
      additional: String
   }

   public entry fun init_attrs(sender: &signer) {
      let sender_addr = signer::address_of(sender);

      assert!(sender_addr == @my_addr, error::invalid_argument(EINVALID_OWNER));

      if(!exists<Attrs>(@my_addr)) {
         move_to(sender, Attrs {
            attrs: table::new(),
            create_attr_events: account::new_event_handle<CreateAttrEvent>(sender),
            update_attr_events: account::new_event_handle<UpdateAttrEvent>(sender),
         })
      };
   }

   public entry fun create_attr(
      sender: &signer,
      id: u64,
      description: String,
      level: u64,
      additional: String
   ) acquires Attrs {
      let sender_addr = signer::address_of(sender);

      assert!(sender_addr == @my_addr, error::invalid_argument(EINVALID_OWNER));
      
      let attrs_data = borrow_global_mut<Attrs>(@my_addr);
      let attrs = &mut attrs_data.attrs;

      assert!(!table::contains(attrs, id), error::invalid_argument(EINVALID_ATTR_ID));

      table::add(attrs, id, Attr {
         id,
         description,
         additional,
         level
      });

      event::emit_event<CreateAttrEvent>(
         &mut attrs_data.create_attr_events,
         CreateAttrEvent { 
            id,
            description,
            level,
            additional
         },
      );
   }

   public entry fun update_attr(
      sender: &signer,
      id: u64,
      description: String,
      level: u64,
      additional: String
   ) acquires Attrs {

      let sender_addr = signer::address_of(sender);

      assert!(sender_addr == @my_addr, error::invalid_argument(EINVALID_OWNER));

      let attrs_data = borrow_global_mut<Attrs>(@my_addr);
      let attrs = &mut attrs_data.attrs;

      assert!(table::contains(attrs, id), error::invalid_argument(EINVALID_ATTR_ID));

      let attr_item = table::borrow_mut(attrs, id);

      attr_item.description = description;
      attr_item.level = level;
      attr_item.additional = additional;

      event::emit_event(&mut attrs_data.update_attr_events, UpdateAttrEvent {
         id,
         description,
         level,
         additional
      })
   }


   // [x] init attrs
   // [x] create attr
   // [x] update exist attr

   #[test(owner = @my_addr)]
   public fun test_init_attrs(owner: &signer) {
      // create account
      account::create_account_for_test(signer::address_of(owner));

      init_attrs(owner);

      // let owner_addr = signer::address_of(owner);
      // let attrs_data = borrow_global_mut<Attrs>(owner_addr);
   }

   #[test(owner = @my_addr)]
   public fun test_create_attr(owner: &signer) acquires Attrs {
      // create account
      account::create_account_for_test(signer::address_of(owner));

      init_attrs(owner);

      create_attr(owner, 1, string::utf8(b"test"), 1, string::utf8(b"test"));

      let attrs_data = borrow_global_mut<Attrs>(signer::address_of(owner));
      let attrs = &mut attrs_data.attrs;

      assert!(table::contains(attrs, 1), 0);

      let attr_item = table::borrow_mut(attrs, 1);

      assert!(attr_item.description == string::utf8(b"test"), 0);
      assert!(attr_item.additional == string::utf8(b"test"), 0);
   }

   #[test(owner = @my_addr)]
   public fun test_update_attr(owner: &signer) acquires Attrs {
      // create account
      account::create_account_for_test(signer::address_of(owner));

      init_attrs(owner);

      create_attr(owner, 1, string::utf8(b"test"), 1, string::utf8(b"test"));
      update_attr(owner, 1, string::utf8(b"updated_test"), 1, string::utf8(b"updated_test"));

      let attrs_data = borrow_global_mut<Attrs>(signer::address_of(owner));
      let attrs = &mut attrs_data.attrs;

      assert!(table::contains(attrs, 1), 0);

      let attr_item = table::borrow_mut(attrs, 1);

      assert!(attr_item.description == string::utf8(b"updated_test"), 0);
      assert!(attr_item.additional == string::utf8(b"updated_test"), 0);
   }
}
