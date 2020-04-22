/**
 * @kind graph
 */

import javascript
import PropagationGraphs

predicate reachableFromSourceCandidate(PropagationGraph::Node src, PropagationGraph::Node nd) {
  src.isSourceCandidate() and
  PropagationGraph::edge(src, nd)
  or
  exists(PropagationGraph::Node mid |
    reachableFromSourceCandidate(src, mid) and
    PropagationGraph::edge(mid, nd)
  )
}

predicate reachableFromSanitizerCandidate(PropagationGraph::Node san, PropagationGraph::Node nd) {
  san.isSanitizerCandidate() and
  PropagationGraph::edge(san, nd)
  or
  exists(PropagationGraph::Node mid |
    reachableFromSanitizerCandidate(san, mid) and
    PropagationGraph::edge(mid, nd)
  )
}

predicate triple(PropagationGraph::Node src, PropagationGraph::Node san, PropagationGraph::Node snk) {
  reachableFromSourceCandidate(src, san) and
  san.isSanitizerCandidate() and
  src.asDataFlowNode().getEnclosingExpr() != san.asDataFlowNode().getEnclosingExpr() and
  reachableFromSanitizerCandidate(san, snk) and
  snk.isSinkCandidate()
  // NB: we do not require `san` and `snk` to be different, since we might have a situation like
  // `sink(sanitize(src))` where `san` and `snk` are both `sanitize(src)`
}

from PropagationGraph::Node src, PropagationGraph::Node san, PropagationGraph::Node snk
where triple(src, san, snk)
select src, san, snk

query predicate seldonConstraint1(
  PropagationGraph::Node src, PropagationGraph::Node san, int snkCount
 ) {
  snkCount = strictcount(PropagationGraph::Node snk | triple(src, san, snk))
 }

query predicate seldonConstraint2(
  PropagationGraph::Node san, PropagationGraph::Node snk, int srcCount
 ) {
  srcCount = strictcount(PropagationGraph::Node src | triple(src, san, snk))
 }

query predicate seldonConstraint3(
  PropagationGraph::Node src, PropagationGraph::Node snk, int sanCount
 ) {
  sanCount = strictcount(PropagationGraph::Node san | triple(src, san, snk))
 }
