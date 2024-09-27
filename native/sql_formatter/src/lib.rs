use rustler::Atom;
use rustler::NifTuple;

use sqlformat::{FormatOptions, Indent, QueryParams};

mod atoms {
    rustler::atoms! {
        ok,
        error
    }
}

#[derive(NifTuple)]
struct StringResultTuple {
    lhs: Atom,
    rhs: String,
}

#[rustler::nif(schedule = "DirtyCpu")]
fn format(sql_query: String) -> StringResultTuple {
    let options = FormatOptions {
        indent: Indent::Spaces(4),
        uppercase: true,
        lines_between_queries: 1,
    };

    let formatted_sql = sqlformat::format(sql_query.as_str(), &QueryParams::None, options);

    return StringResultTuple {
        lhs: atoms::ok(),
        rhs: formatted_sql.to_string(),
    };
}

rustler::init!("Elixir.EctoDbg.SQLFormatter");
