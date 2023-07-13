DROP DATABASE IF EXISTS db;
CREATE DATABASE db;

USE db;

CREATE TABLE a_bank (
  id int(10) NOT NULL AUTO_INCREMENT,
  account_number int(10) unsigned NOT NULL,
  name varchar(255) NOT NULL,
  amount int(100) unsigned NOT NULL,
  updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
);

insert into a_bank (account_number, name, amount) values (1, 'sato',  12);
insert into a_bank (account_number, name, amount) values (2, 'kato', 120);
insert into a_bank (account_number, name, amount) values (3, 'goto',  13);
